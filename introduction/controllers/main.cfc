<cfcomponent output="false">

	<cffunction name="default" output="false">
		<cfargument name="rc" type="struct" />
		
		<cfset var files = 0 />
		
		<cfdirectory action="list" directory="#expandPath(request.base)#../examples/" name="files" />
		
		<cfset rc.files = files />
		
	</cffunction>

</cfcomponent>