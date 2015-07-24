component {
    // copy this to your application root to use as your Application.cfc
    // or incorporate the logic below into your existing Application.cfc

    // you can provide a specific application name if you want:
    this.name = hash( getBaseTemplatePath() );
    // any other application settings:
    this.sessionManagement = true;

    // create your FW/1 application:
    request._framework_one = new framework.one();
    // you can specific FW/1 configuration as an argument:
    // request._framework_one = new framework.one( { trace : true } );
    // if you need to override extension points, use
    // MyApplication.cfc for those and then do:
    // request._framework_one = new MyApplication( { trace : true } );

    // delegation of lifecycle methods to FW/1:
    function onApplicationStart() {
        return request._framework_one.onApplicationStart();
    }
    function onError( exception, event ) {
        return request._framework_one.onError( exception, event );
    }
    function onRequest( targetPath ) {
        return request._framework_one.onRequest( targetPath );
    }
    function onRequestEnd() {
        return request._framework_one.onRequestEnd();
    }
    function onRequestStart( targetPath ) {
        return request._framework_one.onRequestStart( targetPath );
    }
    function onSessionStart() {
        return request._framework_one.onSessionStart();
    }
}
