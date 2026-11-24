component {
    this.name = "fw1-rest-test";
    this.mappings[ "/framework" ] = getDirectoryFromPath( getCurrentTemplatePath() ) & "../../../framework";

    function _get_framework_one() {
        if ( !structKeyExists( request, "_framework_one" ) ) {
            request._framework_one = new framework.one( {
                decodeRequestBody = true,
                reloadApplicationOnEveryRequest = true
            } );
        }
        return request._framework_one;
    }

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
}
