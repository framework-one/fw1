<cfcomponent output="false">
	<cffunction name="init" output="false">
		<cfargument name="fw">
		<cfset variables.fw = arguments.fw> 
	</cffunction>
	<cffunction name="before" output="false">
		<cfargument name="rc">
		<cfparam name="rc.beforeCalls" default="#arrayNew(1)#">
		<cfset arrayAppend( rc.beforeCalls, request.action )>
	</cffunction>
	<cffunction name="default" output="false">
		<cfargument name="rc">
		<cfset rc.foo = 42>
		<cfset variables.fw.service("main.default","data")>
	</cffunction>
	<cffunction name="error" output="false">
		<cfargument name="rc">
		<cfset variables.fw.service("main.error","data")>
	</cffunction>
</cfcomponent>