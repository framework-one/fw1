<cfcomponent extends="org.corfield.framework">
	
	<cfscript>
	this.mappings["/userManager"] = getDirectoryFromPath(getCurrentTemplatePath());
	this.name = 'fw1-userManager';
	
	// FW/1 - configuration:
	variables.framework = {
		home = "user.default"
	};
	//base = replaceNoCase(getDirectoryFromPath(getCurrentTemplatePath()), expandPath(""), "")
	
	function setupApplication() 
	{
		setBeanFactory(createObject("component", "models.ObjectFactory").init(expandPath("./assets/config/beans.xml.cfm")));	
	}
	</cfscript>
	
</cfcomponent>