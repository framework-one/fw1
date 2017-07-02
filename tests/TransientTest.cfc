component extends="mxunit.framework.TestCase" {

    function testNotInjectTransient() {
        variables.factory = new framework.ioc( "/tests/model, /tests/extrabeans",
                                     { transients = [ "fish" ], singulars = { sheep = "bean" } } );
        assertTrue( variables.factory.containsBean( "item" ) );
        assertFalse( variables.factory.isSingleton( "item" ) );
        var user = variables.factory.getBean( "user" );
        var item = user.itemTest();
        assertTrue( isSimpleValue( item ) );
        assertEquals( "missing", item );
    }

    function testConstructWithTransient() {
        variables.factory = new framework.ioc( "/tests/model",
                                     { transients = [ "fish", "services" ] } );
        assertTrue( variables.factory.containsBean( "product" ) );
        assertFalse( variables.factory.isSingleton( "product" ) );
        var user = variables.factory.getBean( "userFish" );
        var product = user.getProduct();
        assertTrue( isObject( product ) );
    }

    function testInitializeWithBeans() {
        variables.factory = new framework.ioc( "/tests/model, /tests/extrabeans",
                                               { transients = [ "fish" ], singulars = { sheep = "bean" } } )
            .addBean( "one", 1 ).addBean( "two", "two" );
        var i = variables.factory.getBean( "item" );
        var n1 = application.itemCount;
        var c = variables.factory.getBean( "construct" );
        assertEquals( 1, c.getOne() );
        assertEquals( "two", c.two );
        assertEquals( n1 + 1, application.itemCount );
    }

    function testInitializeWithConstructorArgs() {
        variables.factory = new framework.ioc( "/tests/model, /tests/extrabeans",
                                               { transients = [ "fish" ], singulars = { sheep = "bean" } } )
            .addBean( "one", 1 ).addBean( "two", "two" );
        var i = variables.factory.getBean( "item" );
        var n1 = application.itemCount;
        var c = variables.factory.getBean( "construct", { one : "one", two : 2, item : "no-op" } );
        assertEquals( "one", c.getOne() );
        assertEquals( 2, c.two );
        assertEquals( n1, application.itemCount );
    }

    function testInitializeWithOnlyConstructorArgs() {
        variables.factory = new framework.ioc( "/tests/extrabeans",
                                               { singulars = { sheep = "bean" } } );
        var i = variables.factory.getBean( "item" );
        var n1 = application.itemCount;
        var c1 = variables.factory.getBean( "construct", { one : "one", two : 2, item : "no-op" } );
        assertTrue( isNull( c1.getOne() ) );
        assertEquals( 2, c1.two );
        assertEquals( n1, application.itemCount );
        var c2 = variables.factory.getBean( "construct", { one : 1, two : "two", item : "something" } );
        assertTrue( isNull( c2.getOne() ) );
        assertEquals( "two", c2.two );
    }

}
