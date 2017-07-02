component extends="mxunit.framework.TestCase" {

    function setup() {
        variables.added =
            new framework.ioc( "" )
            .declare( "known" ).asValue( 42 ).done();
    }

    function testHaveKnownValue() {
        assertEquals( 42, variables.added.getBean( "known" ) );
    }

    function testBeSingleton() {
        assertTrue( variables.added.isSingleton( "known" ) );
    }

    function testHaveKnownMetadata() {
        var info = variables.added.getBeanInfo( "known" );
        assertEquals( 42, info.value );
        assertTrue( info.isSingleton );
    }
}
