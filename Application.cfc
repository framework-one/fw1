<cfcomponent extends="org.corfield.framework"><cfscript>
	// Either put the org folder in your webroot or create a mapping for it!
	
	this.name = 'fw1-root';
	// FW/1 - configuration:
	variables.framework = {
		// controllers/layouts/services/views are in this folder:
		base = getDirectoryFromPath( CGI.SCRIPT_NAME ) & 'introduction'
	};
</cfscript></cfcomponent>