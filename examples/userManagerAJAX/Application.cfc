<cfcomponent extends="org.corfield.framework">
	
	<cfscript>
	this.mappings["/userManagerAJAX"] = getDirectoryFromPath(getCurrentTemplatePath());
	this.name = 'fw1-userManagerAJAX';
	
	// FW/1 - configuration:
	variables.framework = {
		home = "user.default",
		suppressImplicitService = false
	};
	
	function setupApplication() 
	{
		setBeanFactory(createObject("component", "model.ObjectFactory").init(expandPath("./assets/config/beans.xml.cfm")));	
	}
	
	function setupRequest()
	{
		controller( 'user.checkAjaxRequest' );
	}
	</cfscript>
	
	<!--- override FW/1 redirect to automatically append Ajax Request variable --->
	<cffunction name="redirect" access="public" output="false"
			hint="Redirect to the specified action, optionally append specified request context items - or use session.">
		<cfargument name="action" type="string" />
		<cfargument name="preserve" type="string" default="none" />
		<cfargument name="append" type="string" default="none" />
		<cfargument name="path" type="string" default="#variables.framework.baseURL#" />
		<cfargument name="queryString" type="string" default="" />
		
		<cfif arguments.append NEQ "all">
			<cfif arguments.append EQ "none">
				<cfset arguments.append = "" />
			</cfif>
			<cfset arguments.append = listAppend(arguments.append, "isAjaxRequest") />
		</cfif>
		<cfset super.redirect( argumentCollection = arguments ) />
	</cffunction>

</cfcomponent>