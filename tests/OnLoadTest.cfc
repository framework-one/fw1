component extends="mxunit.framework.TestCase" {

    function setup() {
        application.loadCount = 0;
    }

    function testCallOnLoadListener() {
        var bf = new framework.ioc( "" ).onLoad( variables.loader );
        assertEquals( 0, application.loadCount );
        var q = bf.containsBean( "foo" );
        assertEquals( 1, application.loadCount );
    }

    function testNotCallListenerWhenReloaded() {
        var bf = new framework.ioc( "" ).onLoad( variables.loader );
        assertEquals( 0, application.loadCount );
        var q = bf.containsBean( "foo" );
        assertEquals( 1, application.loadCount );
        bf.load();
        assertEquals( 1, application.loadCount );
    }

    function testCallMultipleOnLoadListeners() {
        var bf = new framework.ioc( "" ).onLoad( variables.loader ).onLoad( variables.loader );
        assertEquals( 0, application.loadCount );
        var q = bf.containsBean( "foo" );
        assertEquals( 2, application.loadCount );
    }

    function testBeAbleToUseObjectListener() {
        var listener = new tests.model.services.listener();
        var bf = new framework.ioc( "" ).onLoad( listener );
        assertFalse( listener.isLoaded() );
        var q = bf.containsBean( "foo" );
        assertTrue( listener.isLoaded() );
    }

    function testBeAbleToUseBeanListener() {
        var bf = new framework.ioc( "/tests/model" ).onLoad( "listenerService" );
        var q = bf.containsBean( "foo" );
        assertTrue( bf.getBean( "listener" ).isLoaded() );
    }

    function testBeAbleToUseFunctionExpressionListener() {
      var onLoadHasFired = false;
      var bf = new framework.ioc("/tests/model").onLoad(function(beanFactory){
              onLoadHasFired = true;
          });
      var q = bf.containsBean( "foo" );
      assertTrue( onLoadHasFired );
    }

    private void function loader( any factory ) {
        ++application.loadCount;
    }

    function testBeAbleToListenViaConfig() {
        var listener = new tests.model.services.listener();
        var bf = new framework.ioc( "", { loadListener = listener } );
        assertFalse( listener.isLoaded() );
        var q = bf.containsBean( "foo" );
        assertTrue( listener.isLoaded() );
    }

}
