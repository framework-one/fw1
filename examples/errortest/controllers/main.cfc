<cfcomponent output="false">
	<cffunction name="before" output="false">
		<cfargument name="rc">
		<cfparam name="rc.beforeCalls" default="#arrayNew(1)#">
		<cfset arrayAppend( rc.beforeCalls, request.action )>
	</cffunction>
	<cffunction name="default" output="false">
		<cfargument name="rc">
		<cfset rc.foo = 42>
	</cffunction>
</cfcomponent>