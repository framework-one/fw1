<cfcomponent output="false">
	<cffunction name="default" output="false">
		<cfargument name="foo">
		<!--- cause an exception by referencing undefined variable bar --->
		<cfreturn arguments.foo + bar>
	</cffunction>
</cfcomponent>