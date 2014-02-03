component accessors=true {

    property departmentService;
    property userService;

    function init( fw ) {
        variables.fw = fw;
        return this;
    }

    function default( rc ) {
        rc.message = "Welcome to the Framework One User Manager demo!";
    }

    function delete( rc ) {
        variables.userService.delete( rc.id );
        variables.fw.redirect( "user.list" );
    }

    function form( rc ) {
        rc.user = variables.userService.get( argumentCollection = rc );
        rc.departments = variables.departmentService.list();
    }

    function list( rc ) {
        rc.data = variables.userService.list();
    }

    function start( rc ) {
        var user = variables.userService.get( argumentCollection = rc );
        variables.fw.populate( cfc = user, trim = true );
        if ( structKeyExists( rc, "departmentId" ) && len( rc.departmentId ) ) {
            user.setDepartmentId( rc.departmentId );
            user.setDepartment( variables.departmentService.get( rc.departmentId ) );
        }
        rc.data = variables.userService.save( user );
        variables.fw.redirect( "user.list" );
    }

    function checkAjaxRequest( rc ) {
        var httpData = getHttpRequestData();
        if ( structKeyExists( rc, "isAjaxRequest" ) && isBoolean( rc.isAjxRequest ) ) {
            return;
        }
        rc.isAjxRequest = structKeyExists( httpData, "headers" ) &&
            structKeyExists( httpData.headers, "X-Requested-With" ) &&
            httpData.headers[ "X-Requested-With" ] == "XMLHttpRequest";
    }

}
