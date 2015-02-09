component extends="mxunit.framework.TestCase" {

    function setup() {
        variables.factory = new framework.ioc( "/tests/model", { transients = [ "fish" ] } );
    }

    function shouldHaveBeanServiceButNoShortForm() {
        assertTrue( variables.factory.containsBean( "favaBean" ) );
        assertTrue( variables.factory.containsBean( "favaService" ) );
        assertFalse( variables.factory.containsBean( "fava" ) );
    }

    function shouldHaveProductAndProductService() {
        assertTrue( variables.factory.containsBean( "productService" ) );
        assertTrue( variables.factory.containsBean( "product" ) );
        var svc1 = variables.factory.getBean( "productService" );
        var svc2 = variables.factory.getBean( "product" );
        assertSame( svc1, svc2 );
    }

    function shouldHavePintoAndPintoBean() {
        assertTrue( variables.factory.containsBean( "pintoBean" ) );
        assertTrue( variables.factory.containsBean( "pinto" ) );
        var bean1 = variables.factory.getBean( "pintoBean" );
        var bean2 = variables.factory.getBean( "pinto" );
        assertNotSame( bean1, bean2 );
    }

    function shouldHaveUserAndUserFish() {
        assertTrue( variables.factory.containsBean( "userFish" ) );
        assertTrue( variables.factory.containsBean( "user" ) );
        var user1 = variables.factory.getBean( "userFish" );
        var user2 = variables.factory.getBean( "user" );
        assertNotSame( user1, user2 );
        // but product (service) is injected
        assertSame( user1.getProduct(), user2.getProduct() );
    }

}
