component extends="mxunit.framework.TestCase" {

    function setup() {
        variables.parent = new framework.ioc( "", { constants = { one = 1, two = 2 } } );
        variables.factory = new framework.ioc( "", { constants = { one = "I", three = "III" } } );
        variables.factory.setParent( variables.parent );
    }

    function shouldFindInParent() {
        assertEquals( 2, variables.factory.getBean( "two" ) );
    }

    function shouldFindInChild() {
        assertEquals( "I", variables.factory.getBean( "one" ) );
        assertEquals( "III", variables.factory.getBean( "three" ) );
    }

    function shouldContainViaParent() {
        assertTrue( variables.factory.containsBean( "two" ) );
    }

    function shouldGetMetadataViaParent() {
        var info = variables.factory.getBeanInfo( "two" );
        assertEquals( 2, info.value );
        assertTrue( info.isSingleton );
    }

    function shouldBeSingletonViaParent() {
        assertTrue( variables.factory.isSingleton( "two" ) );
    }

    function shouldHaveParentInMetadata() {
        var info = variables.factory.getBeanInfo();
        assertTrue( structKeyExists( info, "parent" ) );
        assertEquals( variables.parent.getBeanInfo(), info.parent );
    }

    function shouldNotHaveParentWithRegex() {
        var info = variables.factory.getBeanInfo( regex = "X" );
        assertFalse( structKeyExists( info, "parent" ) );
    }

}
