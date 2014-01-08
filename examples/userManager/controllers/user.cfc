component accessors=true {

    property departmentService;
    property userService;

    function init( fw ) {
        variables.fw = fw;
    }

    function default( rc ) {
        rc.message = "Welcome to the Framework One User Manager application demo!";
    }

    function delete( rc ) {
        variables.userService.delete( rc.id );
        variables.fw.frameworkTrace( "deleted user", rc.id );
        variables.fw.redirect( "user.list" );
    }
	
    function form( rc ) {
        rc.user = variables.userService.get( argumentCollection = rc );
        rc.departments = variables.departmentService.list();
    }

    function get( rc ) {
        rc.data = variables.userService.get( rc.id );
    }

    function list( rc ) {
        rc.data = variables.userService.list();
    }

    function save( rc ) {
        var user = getUserService().get( argumentCollection = rc );
        variables.fw.populate( cfc = user, trim = true );
        if ( structKeyExists( rc, "departmentId" ) && len( rc.departmentId ) ) {
            user.setDepartmentId( rc.departmentId );
            user.setDepartment( variables.departmentService.get( rc.departmentId ) );
        }
        variables.userService.save( user );
        variables.fw.frameworkTrace( "added user", user );
        variables.fw.redirect( "user.list" );
    }

}
