<cfcomponent extends="org.corfield.framework"><cfscript>
	// Either put the org folder in your webroot or create a mapping for it!
	
	this.name = 'fw1-examples';
	this.sessionManagement = true;
	// FW/1 - configuration:
	variables.framework = structNew();
	variables.framework.usingSubsystems = true;
	// setting framework.base so the application will work when there is a non-empty context root:
	variables.framework.base = getDirectoryFromPath( CGI.SCRIPT_NAME ).replace( getContextRoot(), '' );
	
</cfscript></cfcomponent>