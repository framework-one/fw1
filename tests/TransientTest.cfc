component extends="mxunit.framework.TestCase" {

    function shouldNotInjectTransient() {
        variables.factory = new ioc( "/tests/model, /tests/extrabeans",
                                     { transients = [ "fish" ], singulars = { sheep = "bean" } } );
        assertTrue( variables.factory.containsBean( "item" ) );
        assertFalse( variables.factory.isSingleton( "item" ) );
        var user = variables.factory.getBean( "user" );
        var item = user.itemTest();
        assertTrue( isSimpleValue( item ) );
        assertEquals( "missing", item );
    }

    function shouldConstructWithTransient() {
        variables.factory = new ioc( "/tests/model",
                                     { transients = [ "fish", "services" ] } );
        assertTrue( variables.factory.containsBean( "product" ) );
        assertFalse( variables.factory.isSingleton( "product" ) );
        var user = variables.factory.getBean( "userFish" );
        var product = user.getProduct();
        assertTrue( isObject( product ) );
    }

}
