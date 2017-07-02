component extends="mxunit.framework.TestCase" {

    function setup() {
        variables.constants = new framework.ioc( "", { constants = { known = 42 } } );
    }

    function testHaveKnownValue() {
        assertEquals( 42, variables.constants.getBean( "known" ) );
    }

    function testBeSingleton() {
        assertTrue( variables.constants.isSingleton( "known" ) );
    }

    function testHaveKnownMetadata() {
        var info = variables.constants.getBeanInfo( "known" );
        assertEquals( 42, info.value );
        assertTrue( info.isSingleton );
    }
}
