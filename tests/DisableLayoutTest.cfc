component extends="tests.InjectableTest" {

    public void function setUp() {
        clearFrameworkFromRequest();
        variables.fw = new framework.one();
        variables.fwvars = getVariablesScope( variables.fw );
        variables.fwvars.framework = {
            base = "/tests/layout"
        };
    }

	function testEnabledLayout() {
        var output = "";
		variables.fw.onRequestStart( "" );
		savecontent variable="output" {
            variables.fw.onRequest( "" );
        }
        //writedump(output);abort;
        assertEquals( trim( output ), "[layout]VIEW[/layout]" );
	}

	function testExplicitlyEnabledLayout() {
		variables.fw.enableLayout();
		var output = "";
		variables.fw.onRequestStart( "" );
		savecontent variable="output" {
            variables.fw.onRequest( "" );
        }
        //writedump(output);abort;
        assertEquals( trim( output ), "[layout]VIEW[/layout]" );
	}


	function testDisabledLayout() {
		variables.fw.disableLayout();
		var output = "";
		variables.fw.onRequestStart( "" );
		savecontent variable="output" {
            variables.fw.onRequest( "" );
        }
        assertEquals( trim( output ), "VIEW" );
	}

	function testReEnabledLayout() {
		variables.fw.disableLayout();
		variables.fw.enableLayout();
		var output = "";
		variables.fw.onRequestStart( "" );
		savecontent variable="output" {
            variables.fw.onRequest( "" );
        }
        assertEquals( trim( output ), "[layout]VIEW[/layout]" );
	}



}
