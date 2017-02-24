component extends="tests.InjectableTest" {

    public void function setUp() {
        clearFrameworkFromRequest();
        variables.fw = new framework.one();
        variables.fwvars = getVariablesScope( variables.fw );
        variables.fwvars.framework = {
            generateSES = true,
            SESOmitIndex = true
        };
    }

    public void function testBuildURL() {
        // ensure SES URL gets generated in onSessionStart:
        variables.fw.setupSession = buildSESURL;
        variables.fwvars.setupSession = buildSESURL;
        variables.fw.__url = "";
        variables.fw.onSessionStart();
        var expected = "/foo/test/bar/1";
        assertEquals( expected, right( variables.fw.__url, len( expected ) ) );
    }

    private void function buildSESURL() {
        this.__url = buildURL( action = "foo.test", queryString = "bar=1" );
    }

    public void function testURLandURI() {
        variables.fw.onRequestStart("/index.cfm");
        assertEquals( "useCgiScriptName", variables.fw.getBaseURL() );
        var suffix = "/tests/";
        assertEquals( suffix,
                      right( variables.fw.buildURL( action = 'main.default' ), len( suffix ) ) );
        suffix &= "main/default";
        assertEquals( suffix,
                      right( variables.fw.buildCustomURL( uri = '/main/default' ), len( suffix ) ) );
    }

    public void function testURLandURIempty() {
        variables.fwvars.framework.baseURL = "/tests/ci/";
        variables.fw.onRequestStart("/index.cfm");
        assertEquals( "/tests/ci", variables.fw.getBaseURL() );
        assertEquals( "/tests/ci", variables.fw.buildURL( action = 'main.default' ) );
        assertEquals( "/tests/ci/main/default", variables.fw.buildCustomURL( uri = '/main/default' ) );
    }

}
