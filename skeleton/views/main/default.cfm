<cfset rc.title = "Default View" />	<!--- set a variable to be used in a layout --->
<p>This is the default view for FW/1.</p>
<!--- use the named result from the service call --->
<p>This page was rendered on <cfoutput>#rc.today#</cfoutput>.</p>