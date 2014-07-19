component accessors=true {

    property departmentService;
    property roleService;
    property userService;

    function init( fw ) {
        variables.fw = fw;
        return this;
    }

    function before( rc ) {
        if ( session.auth.user.getRoleId() != 1 ) { // not admin
            variables.fw.redirect( "main" );
        }
    }

    function form( rc ) {
        if ( !structKeyExists( rc, "user" ) ) {
            param name="rc.id" default="0";
            rc.user = variables.userService.get( rc.id );
        }
        rc.departments = variables.departmentService.list();
        rc.roles = variables.roleService.list();
    }

    function list( rc ) {
        rc.data = variables.userService.list();
    }

    function save( rc ) {
        param name="rc.id" default="0";
        rc.user = variables.userService.get( rc.id );
        rc.message = variables.userService.validate( argumentCollection = rc );

        // if there were validation errors, populate a blank user and redisplay the form
        if ( !arrayIsEmpty( rc.message ) ) {
            rc.user = variables.fw.getBeanFactory().getBean("userBean");
            variables.fw.populate( cfc = rc.user, trim = true );
            variables.fw.redirect( "user.form", "user,message" );
        }

        variables.fw.populate( cfc = rc.user, trim = true );
        // update department
        if ( structKeyExists( rc, "departmentId" ) && len( rc.departmentId ) ) {
            rc.user.setDepartmentId( rc.departmentId );
            rc.user.setDepartment( variables.departmentService.get( rc.departmentId ) );
        }
        // if password provided, update password hash and salt
        if ( structKeyExists( rc, "password" ) && len( rc.password ) ) {
            var newpasshash = variables.userService.hashPassword( rc.password );
            rc.user.setPasswordHash( newpasshash.hash );
            rc.user.setPasswordSalt( newpasshash.salt );
        }
        variables.userService.save( rc.user );
        variables.fw.redirect( "user.list" );
    }

    function delete( rc ) {
        variables.userService.delete( rc.id );
        variables.fw.redirect( "user.list" );
    }
}
