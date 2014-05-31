component extends="mxunit.framework.TestCase" {

    function setup() {
        variables.factory = new framework.ioc( "" );
    }

    function shouldBeAStruct() {
        var info = variables.factory.getBeanInfo();
        assertTrue( isStruct( info ) );
        assertEquals( 1, structCount( info ) );
        assertEquals( "beaninfo", structKeyList( info ) );
    }

    function shouldContainMetadata() {
        var info = variables.factory.getBeanInfo( "beanfactory" );
        assertTrue( isStruct( info ) );
        assertEquals( 2, structCount( info ) );
        assertTrue( structKeyExists( info, "value" ) );
        assertTrue( info.isSingleTon );
    }

    function shouldContainParent() {
        var parent = new framework.ioc( "" );
        variables.factory.setParent( parent );
        var info = variables.factory.getBeanInfo();
        assertTrue( structKeyExists( info, "parent" ) );
        assertTrue( structKeyExists( info.parent, "beaninfo" ) );
    }

    function shouldBeFlat() {
        var parent = new framework.ioc( "" );
        parent.addBean( "father", "figure" );
        variables.factory.setParent( parent );
        var info = variables.factory.getBeanInfo( flatten = true );
        assertFalse( structKeyExists( info, "parent" ) );
        assertTrue( structKeyExists( info, "beaninfo" ) );
        assertTrue( structKeyExists( info.beaninfo, "father" ) );
    }

}
