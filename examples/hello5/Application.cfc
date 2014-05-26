component extends="org.corfield.framework" {

	// setting framework.base so the application will work when there is a non-empty context root:
	variables.root = getDirectoryFromPath( CGI.SCRIPT_NAME ).replaceFirst( getContextRoot(), '' );
	variables.framework = {
        base = variables.root & 'cfml',
	    cfcbase = replace( right( variables.root, len( variables.root ) - 1 ), '/', '.', 'all' ) & 'cfcs'
    };

    function setupApplication() {
        var bf = new framework.ioc( "cfcs/services" );
        setBeanFactory( bf );
    }

}
