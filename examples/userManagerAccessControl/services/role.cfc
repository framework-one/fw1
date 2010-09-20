<cfcomponent displayname="RoleService" output="false">

	<cfset variables.roles = structNew()>

	<cffunction name="init" access="public" output="false" returntype="any">
		<cfscript>
		var role = "";

		// since services are cached role data we'll be persisted
		// ideally, this would be saved elsewhere, e.g. database

		// FIRST
		role = new();
		role.setId("1");
		role.setName("Admin");

		variables.roles[role.getId()] = role;

		// SECOND
		role = new();
		role.setId("2");
		role.setName("User");

		variables.roles[role.getId()] = role;
		</cfscript>

		<cfreturn this>
	</cffunction>

	<cffunction name="get" access="public" output="false" returntype="any">
		<cfargument name="id" type="string" required="true">

		<cfset var result = "">

		<cfif len(id) AND structKeyExists(variables.roles, id)>
			<cfset result = variables.roles[id]>
		<cfelse>
			<cfset result = new()>
		</cfif>

		<cfreturn result>
	</cffunction>

	<cffunction name="list" access="public" output="false" returntype="struct">
		<cfreturn variables.roles>
    </cffunction>

	<cffunction name="new" access="public" output="false" returntype="any">
		<cfreturn createObject("component", "userManager.model.Role").init()>
	</cffunction>

</cfcomponent>