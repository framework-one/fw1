<cfcomponent extends="org.corfield.framework">
	
	<cfscript>
	this.mappings["/userManager"] = getDirectoryFromPath(getCurrentTemplatePath());
	this.name = 'fw1-userManager';
	
	// FW/1 - configuration:
	variables.framework = {
		home = "user.default",
		suppressImplicitService = false
	};
	
	function setupApplication() 
	{
		setBeanFactory(createObject("component", "model.ObjectFactory").init(expandPath("./assets/config/beans.xml.cfm")));	
	}
	</cfscript>
	
</cfcomponent>