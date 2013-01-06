component extends="org.corfield.framework" {
	
	this.mappings["/userManager"] = getDirectoryFromPath(getCurrentTemplatePath());
	this.name = 'fw1-userManager';
	
	// FW/1 - configuration:
	variables.framework = {
		home = "user.default",
		suppressImplicitService = false,
        trace = true
	};
	
	function setupApplication() 
	{
		setBeanFactory(createObject("component", "model.ObjectFactory").init(expandPath("./assets/config/beans.xml.cfm")));	
	}
	
}
