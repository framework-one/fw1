component extends="org.corfield.framework" {

	variables.framework = structNew();
	// setting framework.base so the application will work when there is a non-empty context root:
	variables.root = getDirectoryFromPath( CGI.SCRIPT_NAME ).replace( getContextRoot(), '' );
	variables.framework.base = variables.root & 'cfml';
	variables.framework.cfcbase = replace( right( variables.root, len( variables.root ) - 1 ), '/', '.', 'all' ) & 'cfcs';
    // this example uses the deprecated service() call
    // this example uses the deprecated start/end actions
    variables.framework.suppressServiceQueue = false;

}
