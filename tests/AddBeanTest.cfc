component extends="mxunit.framework.TestCase" {

    function setup() {
        variables.added =
            new framework.ioc( "" )
            .addBean( "known", 42 );
    }

    function shouldHaveKnownValue() {
        assertEquals( 42, variables.added.getBean( "known" ) );
    }

    function shouldBeSingleton() {
        assertTrue( variables.added.isSingleton( "known" ) );
    }

    function shouldHaveKnownMetadata() {
        var info = variables.added.getBeanInfo( "known" );
        assertEquals( 42, info.value );
        assertTrue( info.isSingleton );
    }
}
