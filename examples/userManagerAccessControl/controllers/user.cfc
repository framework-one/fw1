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

	<cffunction name="setRoleService" access="public" output="false">
		<cfargument name="roleService" type="any" required="true" />
		<cfset variables.roleService = arguments.roleService />
	</cffunction>
	<cffunction name="getRoleService" access="public" returntype="any" output="false">
		<cfreturn variables.roleService />
	</cffunction>

	<cffunction name="setUserService" access="public" output="false" returntype="void">
		<cfargument name="userService" type="any" required="true" />
		<cfset variables.userService = arguments.userService />
	</cffunction>
	<cffunction name="getUserService" access="public" output="false" returntype="any">
		<cfreturn variables.userService />
	</cffunction>

	<cffunction name="before" access="public" output="false" returntype="void">
		<cfargument name="rc" type="struct" required="true">
		<!--- if the logged on user is not in the admin role, redirect to main --->
		<cfif session.auth.user.getRoleId() is not 1>
			<cfset variables.fw.redirect('main') />
		</cfif>
	</cffunction>

	<cffunction name="form" access="public" output="false" returntype="void">
		<cfargument name="rc" type="struct" required="true">

		<!--- if the user object does not exist, grab it --->
		<cfif not structkeyexists(rc,'user')>
			<cfset rc.user = getUserService().get(argumentCollection=rc)>
		</cfif>

		<!--- we need to retrieve all access levels and roles for the drop down selection --->
		<cfset rc.departments = getDepartmentService().list()>
		<cfset rc.roles = getRoleService().list()>
	</cffunction>

	<cffunction name="startSave" access="public" output="false" returntype="void">
		<cfargument name="rc" type="struct" required="true">

		<cfset var userService = getUserService() />
		<cfset var newpasshash = '' />

		<!--- validate the user --->
		<cfset rc.user = userService.get(argumentCollection=rc) />
		<cfset rc.message = userService.validate(argumentCollection=rc) />

		<!--- if there were validation errors, grab a blank user to populate and send back to the form --->
		<cfif not arrayIsEmpty(rc.message)>
			<cfset rc.user = userService.new() />
		</cfif>

		<!--- update the user object with the data entered --->
		<cfset variables.fw.populate( cfc = rc.user, trim = true )>

		<!--- if there were error, redirect the user to the form --->
		<cfif not arrayIsEmpty(rc.message)>
			<cfset variables.fw.redirect('user.form','user,message') />
		</cfif>

		<!--- update the user object with the new selection --->
		<cfif structKeyExists(rc, "departmentId") AND len(rc.departmentId)>
			<cfset rc.user.setDepartmentId(rc.departmentId)>
			<cfset rc.user.setDepartment(getDepartmentService().get(rc.departmentId))>
		</cfif>

		<!--- if the password is new, update the user object with the password hash and salt --->
		<cfif structKeyExists(rc, "password") AND len(rc.password)>
			<cfset newpasshash = userService.hashPassword(rc.password) />
			<cfset rc.user.setPasswordHash(newpasshash.hash) />
			<cfset rc.user.setPasswordSalt(newpasshash.salt) />
		</cfif>

	</cffunction>

	<cffunction name="endSave" access="public" output="false" returntype="void">
		<cfargument name="rc" type="struct" required="true">

		<!--- user saved so by default lets go back to the users list page --->
		<cfset variables.fw.redirect("user.list")>
	</cffunction>

	<cffunction name="endDelete" access="public" output="false" returntype="void">
		<cfargument name="rc" type="struct" required="true">

		<!--- user deleted so by default lets go back to the users list page --->
		<cfset variables.fw.redirect("user.list")>
	</cffunction>

</cfcomponent>