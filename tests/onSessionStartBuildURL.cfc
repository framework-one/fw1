component extends="tests.InjectableTest" {

    public void function setUp() {
        clearFrameworkFromRequest();
        variables.fw = new org.corfield.framework();
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

}
