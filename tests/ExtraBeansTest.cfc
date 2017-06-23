component extends="mxunit.framework.TestCase" {

    function testResolveMapping() {
        var factory = new framework.ioc( "/tests/extrabeans" );
        application.itemCount = 0;
        assertTrue( factory.containsBean( "item" ) );
        assertTrue( factory.containsBean( "itemSheep" ) );
        var item1 = factory.getBean( "item" );
        var item2 = factory.getBean( "itemSheep" );
        // since sheep was not specified as singular, item should
        // be a singleton and itemSheep should be an alias to it
        assertSame( item1, item2 );
        assertEquals( 1, application.itemCount );
    }

    function testResolveMappingWithSingular() {
        var factory = new framework.ioc( "/tests/extrabeans",
                               { singulars = { sheep = "bean" } } );
        application.itemCount = 0;
        assertTrue( factory.containsBean( "item" ) );
        assertTrue( factory.containsBean( "itemBean" ) );
        var item1 = factory.getBean( "item" );
        var item2 = factory.getBean( "itemBean" );
        // since sheep was mapped to bean as a singular it should
        // be a transient and those items should be unique
        assertNotSame( item1, item2 );
        assertEquals( 2, application.itemCount );
    }

    function testNotInjectTypedProperty() {
        structDelete( application, "itemCount" );
        variables.factory = new framework.ioc( "/tests/model, /tests/extrabeans",
                                     { singulars = { sheep = "lamb" },
                                       omitTypedProperties = true } );
        assertTrue( variables.factory.containsBean( "item" ) );
        assertTrue( variables.factory.isSingleton( "item" ) );
        assertTrue( variables.factory.containsBean( "itemLamb" ) );
        assertTrue( variables.factory.isSingleton( "itemLamb" ) );
        var user = variables.factory.getBean( "user" );
        var item = user.itemTest();
        assertFalse( isSimpleValue( item ) );
        assertEquals( 1, application.itemCount );
        var lamb = user.getItemLamb();
        assertTrue( isNull( lamb ) );
        assertEquals( 1, application.itemCount );
    }

}
