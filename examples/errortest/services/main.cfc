<cfcomponent output="false">
	<cffunction name="error" output="false">
		<cfreturn "services/main.cfc:error() was called">
	</cffunction>
	<cffunction name="default" output="false">
		<cfargument name="foo">
		<!--- cause an exception by referencing undefined variable bar --->
		<cfreturn arguments.foo + bar>
	</cffunction>
</cfcomponent>