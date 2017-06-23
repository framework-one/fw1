component extends="mxunit.framework.TestCase" {

    function setup() {
        variables.parent = new framework.ioc( "", { constants = { one = 1, two = 2 } } );
        variables.factory = new framework.ioc( "", { constants = { one = "I", three = "III" } } );
        variables.factory.setParent( variables.parent );
    }

    function testFindInParent() {
        assertEquals( 2, variables.factory.getBean( "two" ) );
    }

    function testFindInChild() {
        assertEquals( "I", variables.factory.getBean( "one" ) );
        assertEquals( "III", variables.factory.getBean( "three" ) );
    }

    function testContainViaParent() {
        assertTrue( variables.factory.containsBean( "two" ) );
    }

    function testGetMetadataViaParent() {
        var info = variables.factory.getBeanInfo( "two" );
        assertEquals( 2, info.value );
        assertTrue( info.isSingleton );
    }

    function testBeSingletonViaParent() {
        assertTrue( variables.factory.isSingleton( "two" ) );
    }

    function testHaveParentInMetadata() {
        var info = variables.factory.getBeanInfo();
        assertTrue( structKeyExists( info, "parent" ) );
        assertEquals( variables.parent.getBeanInfo(), info.parent );
    }

    function testNotHaveParentWithRegex() {
        var info = variables.factory.getBeanInfo( regex = "X" );
        assertFalse( structKeyExists( info, "parent" ) );
    }

}
