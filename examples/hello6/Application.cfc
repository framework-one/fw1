<cfcomponent extends="org.corfield.framework"><cfscript>
	this.name = "fw1-hello6";
	this.sessionManagement = true;
	// setting framework.base so the application will work when there is a non-empty context root:
	variables.framework = structNew();
	variables.framework.base = getDirectoryFromPath( CGI.SCRIPT_NAME ).replace( getContextRoot(), '' );
	// reduce contexts to 1 to remove fw1pk from redirect URL:
	variables.framework.maxNumContextsPreserved = 1;
</cfscript></cfcomponent>