component extends="mxunit.framework.TestCase" {

    function setup() {
        application.userServiceCount = 0;
        variables.factory = new framework.ioc( "/tests/model, /tests/services", { transients = [ "fish" ] } );
    }

    function testHaveUserFishAndUserService() {
        assertTrue( variables.factory.containsBean( "userFish" ) );
        assertTrue( variables.factory.containsBean( "userService" ) );
        assertFalse( variables.factory.containsBean( "user" ) );
        var user1 = variables.factory.getBean( "userFish" );
        var user2 = variables.factory.getBean( "userFish" );
        assertNotSame( user1, user2 );
    }

    function testInjectUserServiceIntoProduct() {
        assertEquals( 0, application.userServiceCount );
        var svc1 = variables.factory.getBean( "userService" );
        assertEquals( 1, application.userServiceCount );
        var svc2 = variables.factory.getBean( "userService" );
        assertEquals( 1, application.userServiceCount );
        var svc3 = variables.factory.getBean( "product" );
        assertSame( svc1, svc2 );
        assertEquals( 1, svc1.getId() );
        assertEquals( 1, svc2.getId() );
        assertEquals( 1, svc3.getUserService().getId() );
        assertSame( svc1, svc3.getUserService() );
    }

}
