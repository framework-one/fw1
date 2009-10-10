<cfcomponent output="false">
	<cffunction name="startDefault" output="false">
		<cfargument name="rc">
		<cfparam name="rc.name" default="anonymous">
	</cffunction>
	<cffunction name="endDefault" output="false">
		<cfargument name="rc">
		<cfset rc.name = rc.data>
	</cffunction>
</cfcomponent>