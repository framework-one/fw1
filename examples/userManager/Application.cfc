component extends="org.corfield.framework" {
	
	this.mappings["/userManager"] = getDirectoryFromPath(getCurrentTemplatePath());
	this.name = 'fw1-userManager';
	
	// FW/1 - configuration:
	variables.framework = {
		home = "user.default",
        trace = true
	};
	
	function setupApplication() 
	{
        var beanFactory = new framework.ioc( "model" );
        setBeanFactory( beanFactory );
	}
	
}
