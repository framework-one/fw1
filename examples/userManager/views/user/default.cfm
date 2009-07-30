<p><cfoutput>#rc.message#</cfoutput></p>

<cfif structKeyExists(rc, "reload")>
	<p>The framework cache (and application scope) have been reset.</p>
</cfif>