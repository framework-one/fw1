component extends="mxunit.framework.TestCase" {

    function testSupportBasicFactoryMethod() {
        var bf = new framework.ioc( "/tests/model" );
        bf.declare( "a" ).fromFactory( "factory", "makeMeAnA" );
        assertEquals( "I am an A", bf.getBean( "a" ) );
    }

    function testSupportFactoryFunction() {
        var bf = new framework.ioc( "/tests/model" );
        bf.declare( "a" ).fromFactory( function() {
            return "I am an A";
        } );
        assertEquals( "I am an A", bf.getBean( "a" ) );
    }

    function testSupportFactoryMethodViaBean() {
        var bf = new framework.ioc( "" );
        var factory = new tests.model.services.factory();
        bf.factoryBean( "a", factory, "makeMeAnA" );
        assertEquals( "I am an A", bf.getBean( "a" ) );
    }

    function testSupportFactoryMethodWithBeanArg() {
        var bf = new framework.ioc( "/tests/model" );
        bf.declare( "a" )
            .fromFactory( "factory", "makeAWithFava" )
            .withArguments( [ "favaBean" ] );
        assertEquals( "I am a fava bean", bf.getBean( "a" ) );
    }

    function testSupportFactoryMethodWithLocalArg() {
        var bf = new framework.ioc( "/tests/model" );
        bf.declare( "a" )
            .fromFactory( "factory", "makeAWithFava" )
            .withArguments( [ "favaBean" ] )
            .withOverrides( { favaBean = { stamp = "different" } } );
        assertEquals( "I am a different bean", bf.getBean( "a" ) );
    }

}
