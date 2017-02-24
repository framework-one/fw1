component extends="mxunit.framework.TestCase" {

    function testResolveCircular() {
        var bf = new framework.ioc( "/tests/circular" );
        var a = bf.getBean( "a" );
        var b = bf.getBean( "b" );
        a.getVariables = getVariables;
        b.getVariables = getVariables;
        assertTrue( structKeyExists( a.getVariables(), "b" ) );
        assertTrue( structKeyExists( b.getVariables(), "a" ) );
        assertEquals( a.id, b.getVariables().a.id );
        assertEquals( b.id, a.getVariables().b.id );
        assertFalse( structKeyExists( a, "name" ) );
        assertFalse( structKeyExists( b, "name" ) );
    }

    function testResolveAndConfigureCircular() {
        var bf = new framework.ioc( "/tests/circular", { initMethod = "configure" } );
        var a = bf.getBean( "a" );
        var b = bf.getBean( "b" );
        a.getVariables = getVariables;
        b.getVariables = getVariables;
        assertTrue( structKeyExists( a.getVariables(), "b" ) );
        assertTrue( structKeyExists( b.getVariables(), "a" ) );
        assertEquals( a.id, b.getVariables().a.id );
        assertEquals( b.id, a.getVariables().b.id );
        assertEquals( "A", a.name );
        assertEquals( "B", b.name );
    }

    private function getVariables() {
        return variables;
    }

}
