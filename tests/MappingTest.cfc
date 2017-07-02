component extends="mxunit.framework.TestCase" {

    function testResolveMapping() {
        var factory = new framework.ioc( "/goldfish/trumpets" );
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
        var factory = new framework.ioc( "/goldfish/trumpets",
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

/*
    function testAcceptExpandedPath() {
        // on CI, webroot does not match current directory so this becomes
        // an undeducible path...
        var servicePath = expandPath( "/tests/services" );
        var factory = new framework.ioc( servicePath );
        assertTrue( factory.containsBean( "user" ) );
        assertTrue( factory.containsBean( "userService" ) );
        var svc1 = factory.getBean( "user" );
        var svc2 = factory.getBean( "userService" );
        assertSame( svc1, svc2 );
    }
*/

    function testAcceptRelativePath() {
        var servicePath = "/tests/services";
        var factory = new framework.ioc( servicePath );
        assertTrue( factory.containsBean( "user" ) );
        assertTrue( factory.containsBean( "userService" ) );
        var svc1 = factory.getBean( "user" );
        var svc2 = factory.getBean( "userService" );
        assertSame( svc1, svc2 );
    }

}
