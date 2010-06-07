<cfcomponent extends="org.corfield.framework">

	<cfscript>
	this.mappings["/userManager"] = getDirectoryFromPath(getCurrentTemplatePath());
	this.name = 'fw1-userManager-accessControl';
	this.sessionmanagement = true;
	this.sessiontimeout = createTimeSpan(0,2,0,0);

	// setting framework.base so the application will work when there is a non-empty context root:
	variables.framework = structNew();
	variables.framework.base = getDirectoryFromPath( CGI.SCRIPT_NAME ).replace( getContextRoot(), '' );

	function setupApplication()
	{
		application.adminEmail = 'admin@mysite.com';
		setBeanFactory(createObject("component", "models.ObjectFactory").init(expandPath("./assets/config/beans.xml.cfm")));
	}

	function setupSession() {
		controller( 'security.session' );
	}

	function setupRequest() {
		controller( 'security.authorize' );
	}
	</cfscript>

</cfcomponent>