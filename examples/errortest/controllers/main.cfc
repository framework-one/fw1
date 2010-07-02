<cfcomponent output="false">
	<cffunction name="before" output="false">
		<cfargument name="rc">
		<cfparam name="rc.beforeCount" default="0">
		<cfset rc.beforeCount = rc.beforeCount + 1>
	</cffunction>
	<cffunction name="default" output="false">
		<cfargument name="rc">
		<cfset rc.foo = 42>
	</cffunction>
</cfcomponent>