<cfcomponent output="false">

    <cfproperty name="beanFactory" />

	<cfset variables.roles = structNew()>

	<cffunction name="init" access="public" output="false" returntype="any">
        <cfargument name="beanFactory"/>
        <cfset variables.beanFactory = arguments.beanFactory/>
		<cfscript>
		var role = "";

		// since services are cached role data we'll be persisted
		// ideally, this would be saved elsewhere, e.g. database

		// FIRST
		role = variables.beanFactory.getBean("roleBean");
		role.setId("1");
		role.setName("Admin");

		variables.roles[role.getId()] = role;

		// SECOND
		role = variables.beanFactory.getBean("roleBean");
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
			<cfset result = variables.beanFactory.getBean( "roleBean" )>
		</cfif>

		<cfreturn result>
	</cffunction>

	<cffunction name="list" access="public" output="false" returntype="struct">
		<cfreturn variables.roles>
    </cffunction>

</cfcomponent>
