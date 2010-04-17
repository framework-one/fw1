<cfcomponent output="false" hint="Example non-default service.">
	
	<cffunction name="longdate" output="false">
		<cfargument name="when" hint="Named argument passed implicitly via RC from controller or user." />
		<cfreturn dateFormat( arguments.when, 'long' ) />
	</cffunction>
	
</cfcomponent>