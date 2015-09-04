component {
    // you can provide a specific application name if you want:
	this.name = 'fw1-examples';
    // any other application settings:
    this.sessionManagement = true;
    this.mappings[ '/framework' ] = expandPath( '../framework' );

    // create your FW/1 application:
    request._framework_one = new framework.one( {
		SESOmitIndex = true,
        diLocations = "model, controllers, beans, services", // to account for the variety of D/I locations in our examples
        // that allows all our subsystems to automatically have their own bean factory with the base factory as parent
        trace = true
    } );

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
