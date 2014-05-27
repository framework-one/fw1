component extends="mxunit.framework.TestCase" {

    function setUp() {
        variables.bf = new framework.ioc( "/tests/circular" );
    }

    function shouldResolveCircular() {
        var a = variables.bf.getBean( "a" );
        var b = variables.bf.getBean( "b" );
        a.getVariables = getVariables;
        b.getVariables = getVariables;
        assertTrue( structKeyExists( a.getVariables(), "b" ) );
        assertTrue( structKeyExists( b.getVariables(), "a" ) );
        assertEquals( a.id, b.getVariables().a.id );
        assertEquals( b.id, a.getVariables().b.id );
    }

    private function getVariables() {
        return variables;
    }

}
