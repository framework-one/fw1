component extends="tests.InjectableTest" {

    public void function setUp() {
        clearFrameworkFromRequest();
        variables.fw = new org.corfield.framework();
        variables.fwvars = getVariablesScope( variables.fw );
        variables.fwvars.framework = { };
        variables.fwcfg = variables.fwvars.framework;
        variables.fwcfg.environments = {
            "dev" = { reloadApplicationOnEveryRequest = true },
            "dev-one" = { oneNewOption = 1 },
            "dev-two" = { reloadApplicationOnEveryRequest = false },
            "prod" = { useSSL = true }
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

    public void function testSetupEnvironmentIsCalled() {
        variables.fw.setupEnvironment = recordCallsWithArg;
        variables.fwvars.setupEnvironment = recordCallsWithArg;
        variables.fw.__setupEnvCalls = 0;
        variables.fw.__setupEnvArgs = [ ];
        variables.fw.onRequestStart( "" );
        assertEquals( 1, variables.fw.__setupEnvCalls );
        assertEquals( "", variables.fw.__setupEnvArgs[ 1 ] );
    }

    public void function testSetupEnvironmentIsCalledWithEnv() {
        variables.fw.getEnvironment = returnTierNoMatch;
        variables.fwvars.getEnvironment = returnTierNoMatch;
        variables.fw.setupEnvironment = recordCallsWithArg;
        variables.fwvars.setupEnvironment = recordCallsWithArg;
        variables.fw.__setupEnvCalls = 0;
        variables.fw.__setupEnvArgs = [ ];
        variables.fw.onRequestStart( "" );
        assertEquals( 1, variables.fw.__setupEnvCalls );
        assertEquals( "I do not match any tier", variables.fw.__setupEnvArgs[ 1 ] );
    }

    private void function recordCallsWithArg( string env ) {
        this.__setupEnvCalls += 1;
        arrayAppend( this.__setupEnvArgs, env );
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

    public void function testTierOnlyDev() {
        variables.fw.getEnvironment = returnTierDev;
        variables.fwvars.getEnvironment = returnTierDev;
        variables.fw.onRequestStart( "" );
        assertTrue( variables.fwcfg.reloadApplicationOnEveryRequest, "Reload should be dev: true" );
        assertFalse( structKeyExists( variables.fwcfg, "oneNewOption" ), "OneNewOption should not have been added" );
        assertFalse( structKeyExists( variables.fwcfg, "useSSL" ), "UseSSL should not have been added" );
    }

    private string function returnTierDev() {
        return "dev";
    }

    public void function testTierDevOne() {
        variables.fw.getEnvironment = returnTierDevOne;
        variables.fwvars.getEnvironment = returnTierDevOne;
        variables.fw.onRequestStart( "" );
        assertTrue( variables.fwcfg.reloadApplicationOnEveryRequest, "Reload should be dev: true" );
        assertTrue( structKeyExists( variables.fwcfg, "oneNewOption" ), "OneNewOption should be present" );
        assertFalse( structKeyExists( variables.fwcfg, "useSSL" ), "UseSSL should not have been added" );
    }

    private string function returnTierDevOne() {
        return "dev-one";
    }

    public void function testTierDevTwo() {
        variables.fw.getEnvironment = returnTierDevTwo;
        variables.fwvars.getEnvironment = returnTierDevTwo;
        variables.fw.onRequestStart( "" );
        assertFalse( variables.fwcfg.reloadApplicationOnEveryRequest, "Reload should be dev-one: false (dev-two overrides dev)" );
        assertFalse( structKeyExists( variables.fwcfg, "oneNewOption" ), "OneNewOption should not have been added" );
        assertFalse( structKeyExists( variables.fwcfg, "useSSL" ), "UseSSL should not have been added" );
    }

    private string function returnTierDevTwo() {
        return "dev-two";
    }

    public void function testTierDevNone() {
        variables.fw.getEnvironment = returnTierDevNone;
        variables.fwvars.getEnvironment = returnTierDevNone;
        variables.fw.onRequestStart( "" );
        assertTrue( variables.fwcfg.reloadApplicationOnEveryRequest, "Reload should be dev: true (dev-none introduces no override)" );
        assertFalse( structKeyExists( variables.fwcfg, "oneNewOption" ), "OneNewOption should not have been added" );
        assertFalse( structKeyExists( variables.fwcfg, "useSSL" ), "UseSSL should not have been added" );
    }

    private string function returnTierDevNone() {
        return "dev-none";
    }

    public void function testTierProdOnly() {
        variables.fw.getEnvironment = returnTierProd;
        variables.fwvars.getEnvironment = returnTierProd;
        variables.fw.onRequestStart( "" );
        assertFalse( variables.fwcfg.reloadApplicationOnEveryRequest, "Reload should be prod: false" );
        assertFalse( structKeyExists( variables.fwcfg, "oneNewOption" ), "OneNewOption should not have been added" );
        assertTrue( structKeyExists( variables.fwcfg, "useSSL" ), "UseSSL should be present" );
        assertTrue( variables.fwcfg.useSSL, "UseSSL should be true" );
    }

    private string function returnTierProd() {
        return "prod";
    }

    public void function testTierProdPlus() {
        variables.fw.getEnvironment = returnTierProdPlus;
        variables.fwvars.getEnvironment = returnTierProdPlus;
        variables.fw.onRequestStart( "" );
        assertFalse( variables.fwcfg.reloadApplicationOnEveryRequest, "Reload should be prod: false" );
        assertFalse( structKeyExists( variables.fwcfg, "oneNewOption" ), "OneNewOption should not have been added" );
        assertTrue( structKeyExists( variables.fwcfg, "useSSL" ), "UseSSL should be present" );
        assertTrue( variables.fwcfg.useSSL, "UseSSL should be true" );
    }

    private string function returnTierProdPlus() {
        return "prod-plus";
    }

    public void function testHostname() {
        // just tests we get a non-empty string
        assertNotEquals( "", variables.fw.getHostname() );
    }

}
