component extends="mxunit.framework.TestCase" {

    function shouldResolveMapping() {
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

    function shouldResolveMappingWithSingular() {
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

}
