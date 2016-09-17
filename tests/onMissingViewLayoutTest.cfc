component extends="tests.InjectableTest" {

    public void function setUp() {
        clearFrameworkFromRequest();
        variables.fw = new framework.one();
        variables.fwvars = getVariablesScope( variables.fw );
        variables.fwvars.framework = {
            base = "/tests/omv"
        };
        structDelete( request, "layout" );
    }

    public void function testSetLayout() {
        // should be able to run setLayout() in onMissingView() and have it choose the layout
        variables.fw.onMissingView = selectLayoutTwo;
        variables.fwvars.onMissingView = selectLayoutTwo;
        variables.fw.onRequestStart( "" );
        var output = "";
        savecontent variable="output" {
            variables.fw.onRequest( "" );
        }
        assertEquals( "[TWOTEST]", trim( output ) );
    }

    public void function testSetLayoutNoCascade() {
        // should be able to run setLayout() in onMissingView() and have it choose the layout
        variables.fw.onMissingView = selectLayoutTwoNoCascade;
        variables.fwvars.onMissingView = selectLayoutTwoNoCascade;
        variables.fw.onRequestStart( "" );
        var output = "";
        savecontent variable="output" {
            variables.fw.onRequest( "" );
        }
        assertEquals( "TWOTEST", trim( output ) );
    }

    public void function testCustomRenderer() {
        var omv = function( rc ) {
            request.layout = false;
            return {
                contentType = "text/html; charset=utf-8",
                output = "custom output"
            };
        };
        variables.fw.onMissingView = omv;
        variables.fwvars.onMissingView = omv;
        variables.fw.onRequestStart( "" );
        var output = "";
        savecontent variable="output" {
            variables.fw.onRequest( "" );
        }
        assertEquals( "custom output", trim( output ) );
    }

    private string function selectLayoutTwo( struct rc ) {
        setLayout( "main.two" );
        return view( "main/test" );
    }

    private string function selectLayoutTwoNoCascade( struct rc ) {
        setLayout( "main.two", true );
        return view( "main/test" );
    }

}
