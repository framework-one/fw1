component accessors=true {

    property userService;

    function init( fw ) {
        variables.fw = fw;
    }

    function password( rc ) {
        rc.id = session.auth.user.getId();
    }

    function change( rc ) {
        rc.user = variables.userService.get( rc.id );
        rc.message = variables.userService.checkPassword( argumentCollection = rc );
        if ( !arrayIsEmpty( rc.message ) ) {
            variables.fw.redirect( "main.password", "message" );
        }
        var newPasswordHash = variables.userService.hashPassword( rc.newPassword );
        rc.passwordHash = newPasswordHash.hash;
        rc.passwordSalt = newPasswordHash.salt;
        // this will update any user fields from RC so it's a bit overkill here
        variables.fw.populate( cfc = rc.user, trim = true );

        variables.userService.save( rc.user );
        rc.message = ["Your password was changed"];
        variables.fw.redirect( "main", "message" );
    }

}
