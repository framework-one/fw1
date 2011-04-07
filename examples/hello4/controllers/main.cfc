<cfcomponent output="false">
	<cffunction name="init" output="false">
		<cfargument name="fw">
		<cfset variables.fw = arguments.fw> 
	</cffunction>
	<cffunction name="startDefault" output="false">
		<cfargument name="rc">
		<cfparam name="rc.name" default="anonymous">
		<cfset variables.fw.service("main.default","data")>
	</cffunction>
	<cffunction name="endDefault" output="false">
		<cfargument name="rc">
		<cfset rc.name = rc.data>
	</cffunction>
</cfcomponent>