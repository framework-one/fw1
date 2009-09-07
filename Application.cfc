<cfcomponent extends="org.corfield.framework"><cfscript>
	// Either put the org folder in your webroot or create a mapping for it!
	
	this.name = 'fw1-root';
	// FW/1 - configuration:
	variables.framework = structNew();
	// controllers/layouts/services/views are in this folder:
	variables.framework.base = getDirectoryFromPath( CGI.SCRIPT_NAME ) & 'introduction';
	
	// The above code is for OpenBD 1.1. On CF8 and Railo 3.1 you could just do:
	// variables.framework = {
	// 		base = getDirectoryFromPath( CGI.SCRIPT_NAME ) & 'introduction';
	// }

</cfscript></cfcomponent>