component accessors=true {

    property userService;

    function init( fw ) {
        variables.fw = fw;
        return this;
    }

    function before( rc ) {
        if ( structKeyExists( session, "auth" ) && session.auth.isLoggedIn &&
             variables.fw.getItem() != "logout" ) {
            variables.fw.redirect( "main" );
        }
    }

    function login( rc ) {
        // if the form variables do not exist, redirect to the login form
        if ( !structKeyExists( rc, "email" ) || !structKeyExists( rc, "password" ) ) {
            variables.fw.redirect( "login" );
        }
        // look up the user's record by the email address
        var user = variables.userService.getByEmail( rc.email );
        // if that's a real user, verify their password is also correct
        var userValid = user.getId() ? variables.userService.validatePassword( user, rc.password ) : false;
        // on invalid credentials, redisplay the login form
        if ( !userValid ) {
            rc.message = ["Invalid Username or Password"];
            variables.fw.redirect( "login", "message" );
        }
        // set session variables from valid user
        session.auth.isLoggedIn = true;
        session.auth.fullname = user.getFirstName() & " " & user.getLastName();
        session.auth.user = user;

        variables.fw.redirect( "main" );
    }

    function logout( rc ) {
        // reset session variables
        session.auth.isLoggedIn = false;
        session.auth.fullname = "Guest";
        structdelete( session.auth, "user" );
        rc.message = ["You have safely logged out"];
        variables.fw.redirect( "login", "message" );
    }

}
