component extends="mxunit.framework.TestCase" {

    function setup() {
        application.loadCount = 0;
    }

    function shouldCallOnLoadListener() {
        var bf = new framework.ioc( "" ).onLoad( variables.loader );
        assertEquals( 0, application.loadCount );
        var q = bf.containsBean( "foo" );
        assertEquals( 1, application.loadCount );
    }

    function shouldNotCallListenerWhenReloaded() {
        var bf = new framework.ioc( "" ).onLoad( variables.loader );
        assertEquals( 0, application.loadCount );
        var q = bf.containsBean( "foo" );
        assertEquals( 1, application.loadCount );
        bf.load();
        assertEquals( 1, application.loadCount );
    }

    function shouldCallMultipleOnLoadListeners() {
        var bf = new framework.ioc( "" ).onLoad( variables.loader ).onLoad( variables.loader );
        assertEquals( 0, application.loadCount );
        var q = bf.containsBean( "foo" );
        assertEquals( 2, application.loadCount );
    }

    function shouldBeAbleToUseObjectListener() {
        var listener = new tests.model.services.listener();
        var bf = new framework.ioc( "" ).onLoad( listener );
        assertFalse( listener.isLoaded() );
        var q = bf.containsBean( "foo" );
        assertTrue( listener.isLoaded() );
    }

    function shouldBeAbleToUseBeanListener() {
        var bf = new framework.ioc( "/tests/model" ).onLoad( "listenerService" );
        var q = bf.containsBean( "foo" );
        assertTrue( bf.getBean( "listener" ).isLoaded() );
    }

     function shouldBeAbleToUseFunctionExpressionListener() {
        
        if (listFirst(server.coldfusion.productVersion) >= 10) {

            var onLoadHasFired = false;
            var bf = new framework.ioc("/tests/model").onLoad(function(beanFactory){
                    onLoadHasFired = true;
                });
            var q = bf.containsBean( "foo" );
            assertTrue( onLoadHasFired );    
        }
        
    }

    private void function loader( any factory ) {
        ++application.loadCount;
    }

    function shouldBeAbleToListenViaConfig() {
        var listener = new tests.model.services.listener();
        var bf = new framework.ioc( "", { loadListener = listener } );
        assertFalse( listener.isLoaded() );
        var q = bf.containsBean( "foo" );
        assertTrue( listener.isLoaded() );
    }

}
