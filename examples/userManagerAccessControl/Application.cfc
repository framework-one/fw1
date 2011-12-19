<cfcomponent extends="org.corfield.framework">

	<cfscript>
	this.mappings["/userManager"] = getDirectoryFromPath(getCurrentTemplatePath());
	this.name = 'fw1-userManager-accessControl';
	this.sessionmanagement = true;
	this.sessiontimeout = createTimeSpan(0,2,0,0);
	
	// FW/1 - configuration:
	variables.framework = {
		suppressImplicitService = false
	};

	function setupApplication()
	{
		application.adminEmail = 'admin@mysite.com';
		setBeanFactory(createObject("component", "model.ObjectFactory").init(expandPath("./assets/config/beans.xml.cfm")));
	}

	function setupSession() {
		controller( 'security.session' );
	}

	function setupRequest() {
		controller( 'security.authorize' );
	}
	</cfscript>

</cfcomponent>