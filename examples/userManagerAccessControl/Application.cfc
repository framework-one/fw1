component extends="org.corfield.framework" {

	this.mappings["/userManager"] = getDirectoryFromPath(getCurrentTemplatePath());
	this.name = 'fw1-userManager-accessControl';
	this.sessionmanagement = true;
	this.sessiontimeout = createTimeSpan(0,2,0,0);
	
	// FW/1 - configuration:
	variables.framework = {
        trace = true
	};

	function setupApplication()
	{
		application.adminEmail = 'admin@mysite.com';
		setBeanFactory( new framework.ioc( 'model' ) );
	}

	function setupSession() {
		controller( 'security.session' );
	}

	function setupRequest() {
		controller( 'security.authorize' );
	}

}
