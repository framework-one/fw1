<cfcomponent output="false">

	<cffunction name="init" output="false">
		<cfargument name="fw" />
		<cfset variables.fw = arguments.fw />
	</cffunction>

	<cffunction name="default" output="false">
		<cfargument name="rc" />
		<cfparam name="rc.name" default="anonymous" />
	</cffunction>

	<cffunction name="submit" output="false">
		<cfargument name="rc" />
		<!---
			redirect and preserve all request context - could just specify
			"name" to be preserved since we don't need action and submit
		--->
		<cfset variables.fw.redirect( "main.default", "all" ) />
	</cffunction>

</cfcomponent>