component extends="org.corfield.framework" {

	this.mappings["/userManager"] = getDirectoryFromPath(getCurrentTemplatePath());
	this.name = 'fw1-userManager-accessControl';
	this.sessionmanagement = true;
	this.sessiontimeout = createTimeSpan(0,2,0,0);
	
	// FW/1 - configuration:
	variables.framework = {
		suppressImplicitService = false,
        // this example uses the deprecated service() call
        // this example uses the deprecated start/end actions
        suppressServiceQueue = false
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
