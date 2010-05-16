<cfif structKeyExists(rc, "reload")>
	<p>The framework cache (and application scope) have been reset.</p>
</cfif>

<cfoutput><p>Welcome, #session.auth.fullname#</p></cfoutput>