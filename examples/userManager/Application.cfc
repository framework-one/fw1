<cfcomponent extends="org.corfield.framework">
	
	<cfscript>
	this.mappings["/userManager"] = getDirectoryFromPath(getCurrentTemplatePath());
	this.name = 'fw1-userManager';
	
	// FW/1 - configuration:
	variables.framework = {
		home = "user.default"
	};
	// setting framework.base so the application will work when there is a non-empty context root:
	variables.framework.base = getDirectoryFromPath( CGI.SCRIPT_NAME ).replace( getContextRoot(), '' );
	
	function setupApplication() 
	{
		setBeanFactory(createObject("component", "models.ObjectFactory").init(expandPath("./assets/config/beans.xml.cfm")));	
	}
	</cfscript>
	
</cfcomponent>