<cfcomponent displayname="User" output="false">
	
	<cfset variables.fw = "">
	
	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="fw">
		
		<cfset variables.fw = arguments.fw>
		
		<cfreturn this>
	</cffunction>
	
	<cffunction name="setDepartmentService" access="public" output="false">
		<cfargument name="departmentService" type="any" required="true" />
		<cfset variables.departmentService = arguments.departmentService />
	</cffunction>
	<cffunction name="getDepartmentService" access="public" returntype="any" output="false">
		<cfreturn variables.departmentService />
	</cffunction>
	
	<cffunction name="setUserService" access="public" output="false" returntype="void">
		<cfargument name="userService" type="any" required="true" />
		<cfset variables.userService = arguments.userService />
	</cffunction>
	<cffunction name="getUserService" access="public" output="false" returntype="any">
		<cfreturn variables.userService />
	</cffunction>
	
	<cffunction name="default" access="public" output="false" returntype="void">
		<cfargument name="rc" type="struct" required="true">
		
		<cfset rc.message = "Welcome to the Framework One User Manager application demo!">
	</cffunction>
	
	<cffunction name="delete" access="public" output="false" returntype="void">
		<cfargument name="rc" type="struct" required="true">
		<cfset variables.userService.delete( rc.id ) />
		<!--- user deleted so by default lets go back to the users list page --->
		<cfset variables.fw.redirect("user.list")>
	</cffunction>
	
	<cffunction name="form" access="public" output="false" returntype="void">
		<cfargument name="rc" type="struct" required="true">
		
		<!--- sending as named arguments, service will handle validation, returns new user if not found --->
		<cfset rc.user = getUserService().get(argumentCollection=rc)>
		
		<!--- we need to retrieve all departments for the drop down selection --->
		<cfset rc.departments = getDepartmentService().list()>
	</cffunction>

    <cfscript>
    function get( rc ) {
        rc.data = variables.userService.get( rc.id );
    }

    function list( rc ) {
        rc.data = variables.userService.list();
    }
    </cfscript>
	
	<cffunction name="save" access="public" output="false" returntype="void">
		<cfargument name="rc" type="struct" required="true">
		
		<cfset var userService = getUserService()>
		<cfset var user = "">
		
		<!--- sending as named arguments, service will handle validation, returns new user if not found --->
		<cfset user = userService.get(argumentCollection=rc)>
		
		<!--- update our user object with the data entered --->
		<cfset variables.fw.populate( cfc = user, trim = true )>
		
		<!--- update the department object with the new selection --->
		<cfif structKeyExists(rc, "departmentId") AND len(rc.departmentId)>
			<cfset user.setDepartmentId(rc.departmentId)>
			<cfset user.setDepartment(getDepartmentService().get(rc.departmentId))>
		</cfif>
		
        <cfset variables.userService.save( user ) />
		
		<!--- user saved so by default lets go back to the users list page --->
		<cfset variables.fw.redirect("user.list")>
	</cffunction>
	
</cfcomponent>
