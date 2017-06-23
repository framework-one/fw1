component extends="mxunit.framework.TestCase" {

    function setup() {
        variables.factory = new framework.ioc( "" );
    }

    function testBeAStruct() {
        var info = variables.factory.getBeanInfo();
        assertTrue( isStruct( info ) );
        assertEquals( 1, structCount( info ) );
        assertEquals( "beaninfo", structKeyList( info ) );
    }

    function testContainMetadata() {
        var info = variables.factory.getBeanInfo( "beanfactory" );
        assertTrue( isStruct( info ) );
        assertEquals( 2, structCount( info ) );
        assertTrue( structKeyExists( info, "value" ) );
        assertTrue( info.isSingleTon );
    }

    function testContainParent() {
        var parent = new framework.ioc( "" );
        variables.factory.setParent( parent );
        var info = variables.factory.getBeanInfo();
        assertTrue( structKeyExists( info, "parent" ) );
        assertTrue( structKeyExists( info.parent, "beaninfo" ) );
    }

    function testBeFlat() {
        var parent = new framework.ioc( "" );
        parent.declare( "father" ).asValue( "figure" );
        variables.factory.setParent( parent );
        var info = variables.factory.getBeanInfo( flatten = true );
        assertFalse( structKeyExists( info, "parent" ) );
        assertTrue( structKeyExists( info, "beaninfo" ) );
        assertTrue( structKeyExists( info.beaninfo, "father" ) );
    }

    function testMatchRegex() {
        variables.factory
            .declare( "father" ).asValue( "figure" ).done()
            .addBean( "mother", "figure" );
        var info = variables.factory.getBeanInfo( regex = "her$" );
        assertEquals( 2, structCount( info.beaninfo ) );
        assertTrue( structKeyExists( info.beaninfo, "father" ) );
        assertTrue( structKeyExists( info.beaninfo, "mother" ) );
        info = variables.factory.getBeanInfo( regex = "^f" );
        assertEquals( 1, structCount( info.beaninfo ) );
        assertTrue( structKeyExists( info.beaninfo, "father" ) );
        assertFalse( structKeyExists( info.beaninfo, "mother" ) );
        info = variables.factory.getBeanInfo( regex = "child" );
        assertEquals( 0, structCount( info.beaninfo ) );
        assertFalse( structKeyExists( info.beaninfo, "father" ) );
        assertFalse( structKeyExists( info.beaninfo, "mother" ) );
    }


    function testMatchRegexWithParent() {
        variables.factory.addBean( "father", "figure" );
        var parent = new framework.ioc( "" );
        variables.factory.setParent( parent );
        parent.addBean( "mother", "figure" );
        var info = variables.factory.getBeanInfo( regex = "her$" );
        assertEquals( 2, structCount( info.beaninfo ) );
        assertTrue( structKeyExists( info.beaninfo, "father" ) );
        assertTrue( structKeyExists( info.beaninfo, "mother" ) );
        info = variables.factory.getBeanInfo( regex = "^f" );
        assertEquals( 1, structCount( info.beaninfo ) );
        assertTrue( structKeyExists( info.beaninfo, "father" ) );
        assertFalse( structKeyExists( info.beaninfo, "mother" ) );
        info = variables.factory.getBeanInfo( regex = "child" );
        assertEquals( 0, structCount( info.beaninfo ) );
        assertFalse( structKeyExists( info.beaninfo, "father" ) );
        assertFalse( structKeyExists( info.beaninfo, "mother" ) );
    }

}
