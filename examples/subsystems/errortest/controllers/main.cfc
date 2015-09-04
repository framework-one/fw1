component accessors=true {

    property mainService;

    function init( fw ) {
        variables.fw = fw;
    }

    function before( rc ) {
        if ( !structKeyExists( rc, "beforeCalls" ) ) rc.beforeCalls = [ ];
        arrayAppend( rc.beforeCalls, request.action );
    }

    function default( rc ) {
        rc.data = variables.mainService.default( 42 );
    }

    function error( rc ) {
        rc.data = variables.mainService.error();
    }

}
