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

}
