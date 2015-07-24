component extends="framework.one" {
	
	// Either put the framework folder in your webroot or create a mapping for it!
	
	// FW/1 - configuration for introduction application:
	// controllers/layouts/services/views are in this folder (allowing for non-empty context root):
	variables.framework = {
		base = getDirectoryFromPath( CGI.SCRIPT_NAME ).replaceFirst( getContextRoot(), '' ) & 'introduction'
	};

}
