/**
 * I am the Security controller
 */
component {

    function init( fw ) {
        variables.fw = fw;
    }

    function session( rc ) {
        // set up the user's session
        session.auth = {};
        session.auth.isLoggedIn = false;
        session.auth.userId = '0';
        session.auth.userName = 'Guest';
    }

    function authorize( rc ) {
        // check to make sure the user is logged on
        if ( !session.auth.isLoggedIn &&
                not listfindnocase( 'main.default', variables.fw.getFullyQualifiedAction() ) &&
                not listfindnocase( 'user.login', variables.fw.getFullyQualifiedAction() ) &&
                not listfindnocase( 'user.register', variables.fw.getFullyQualifiedAction() ) &&
                not listfindnocase( 'user.authenticate', variables.fw.getFullyQualifiedAction() ) &&
                not listfindnocase( 'main.error', variables.fw.getFullyQualifiedAction() ) ) {
            variables.fw.redirect('main.default');
        }
    }

}
