component accessors=true extends="framework.one" {

	property departmentService;

	this.mappings["/userManager"] = getDirectoryFromPath(getCurrentTemplatePath());
	this.name = 'fw1-userManager-accessControl-5';
	this.sessionmanagement = true;
	this.sessiontimeout = createTimeSpan(0,2,0,0);

	// FW/1 - configuration:
	variables.framework = {
        trace = true
	};

	function setupApplication() {
		application.adminEmail = 'admin@mysite.com';
		if ( variables.keyExists( "departmentService" ) )
			writeDump( var = variables.departmentService, label = "setupApplication" );
	}

	function setupSession() {
		controller( 'security.session' );
		if ( variables.keyExists( "departmentService" ) )
			writeDump( var = variables.departmentService, label = "setupSession" );
	}

	function setupRequest() {
		controller( 'security.authorize' );
		if ( variables.keyExists( "departmentService" ) )
			writeDump( var = variables.departmentService, label = "setupRequest" );
	}

	function setupView( rc ) {
		if ( variables.keyExists( "departmentService" ) ) {
			writeDump( var = variables.departmentService, label = "setupView" );
			rc.d1 = departmentService.get( 1 );
		}
	}

}
