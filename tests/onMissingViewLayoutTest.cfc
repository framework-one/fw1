component extends="tests.InjectableTest" {

    public void function setUp() {
        clearFrameworkFromRequest();
        variables.fw = new org.corfield.framework();
        variables.fwvars = getVariablesScope( variables.fw );
        variables.fwvars.framework = {
            base = "/tests/omv"
        };
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
        assertEquals( "TWOTEST", trim( output ) );
    }

    private string function selectLayoutTwo( struct rc ) {
        setLayout( "main.two" );
        return view( "main/test" );
    }

}
