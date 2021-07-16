component {

	this.name = "renderer_example";

	this.mappings["/framework"] = expandPath("../../framework");

    function _get_framework_one() {
        if ( !structKeyExists( request, '_framework_one' ) ) {

            // create your FW/1 application:
            request._framework_one = new MyApplication();

        }
        return request._framework_one;
    }

	// delegation of lifecycle methods to FW/1:
	function onApplicationStart() {
		return _get_framework_one().onApplicationStart();
	}
	function onError( exception, event ) {
		return _get_framework_one().onError( exception, event );
	}
	function onRequest( targetPath ) {
		return _get_framework_one().onRequest( targetPath );
	}
	function onRequestEnd() {
		return _get_framework_one().onRequestEnd();
	}
	function onRequestStart( targetPath ) {
		return _get_framework_one().onRequestStart( targetPath );
	}
	function onSessionStart() {
		return _get_framework_one().onSessionStart();
	}
	function onMissingView() {
		return _get_framework_one().onMissingView();
	}
	function onReload() {
		return _get_framework_one().onReload();
	}
}
