component {

    function init( fw ) {
        variables.fw = fw;
    }

    function session( rc ) {
        // set up the user's session
        session.auth = {};
        session.auth.isLoggedIn = false;
        session.auth.fullname = 'Guest';
    }

    function authorize( rc ) {
        // check to make sure the user is logged on
        if ( not ( structKeyExists( session, "auth" ) && session.auth.isLoggedIn ) && 
             !listfindnocase( 'login', variables.fw.getSection() ) && 
             !listfindnocase( 'main.error', variables.fw.getFullyQualifiedAction() ) ) {
            variables.fw.redirect('login');
        }
    }

}
