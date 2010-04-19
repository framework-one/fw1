<cfset request.layout = not rc.isAjaxRequest />
<!--- output what the framework already has as a view --->
<cfoutput>#body#</cfoutput>