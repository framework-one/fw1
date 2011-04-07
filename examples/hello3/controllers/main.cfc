<cfcomponent output="false">
	<cffunction name="init" output="false">
		<cfargument name="fw">
		<cfset variables.fw = arguments.fw> 
	</cffunction>
	<cffunction name="default" output="false">
		<cfargument name="rc">
		<cfparam name="rc.name" default="anonymous">
		<cfset variables.fw.service("main.default","data")>
	</cffunction>
</cfcomponent>