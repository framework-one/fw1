<cfcomponent extends="org.corfield.framework"><cfscript>
	this.name = 'fw1-hello7';
	// setting framework.base so the application will work when there is a non-empty context root:
	variables.framework = structNew();
	variables.framework.base = getDirectoryFromPath( CGI.SCRIPT_NAME ).replace( getContextRoot(), '' );
</cfscript></cfcomponent>