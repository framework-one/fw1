component extends="tests.InjectableTest" {

    public void function setUp() {
        structClear( request );
        variables.fw = new org.corfield.framework();
        variables.fwvars = getVariablesScope( variables.fw );
        variables.fwvars.framework = { };
        variables.fwcfg = variables.fwvars.framework;
        variables.fwcfg.environments = {
            "dev" = { reloadApplicationOnEveryRequest = true },
            "dev-one" = { oneNewOption = 1 },
            "dev-two" = { reloadApplicationOnEveryRequest = false },
            "prod" = { useSSL = true },
        };
    }

    public void function testGetEnvironmentIsCalled() {
        variables.fw.getEnvironment = recordCalls;
        variables.fwvars.getEnvironment = recordCalls;
        variables.fw.__getEnvCalls = 0;
        variables.fw.onRequestStart( "" );
        assertEquals( 1, variables.fw.__getEnvCalls );
    }

    private string function recordCalls() {
        this.__getEnvCalls += 1;
        return "";
    }

    public void function testDefault() {
        variables.fw.onRequestStart( "" );
        assertFalse( variables.fwcfg.reloadApplicationOnEveryRequest, "Reload should be default: false" );
        assertFalse( structKeyExists( variables.fwcfg, "oneNewOption" ), "OneNewOption should not have been added" );
        assertFalse( structKeyExists( variables.fwcfg, "useSSL" ), "UseSSL should not have been added" );
    }

    public void function testTierOnlyNoMatch() {
        variables.fw.getEnvironment = returnTierNoMatch;
        variables.fwvars.getEnvironment = returnTierNoMatch;
        variables.fw.onRequestStart( "" );
        assertFalse( variables.fwcfg.reloadApplicationOnEveryRequest, "Reload should be default: false" );
        assertFalse( structKeyExists( variables.fwcfg, "oneNewOption" ), "OneNewOption should not have been added" );
        assertFalse( structKeyExists( variables.fwcfg, "useSSL" ), "UseSSL should not have been added" );
    }

    private string function returnTierNoMatch() {
        return "I do not match any tier";
    }

}
