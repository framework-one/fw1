<cfset httpData = getHttpRequestData()>

<!--- 
	when using jQuery it will send a custom header named X-Requested-With 
	with a value of "XMLHttpRequest" indicating that the request was done 
	through AJAX and if so we want to return our views with no layout
 --->
<cfif structKeyExists(httpData, "headers") 
	AND structKeyExists(httpData.headers, "X-Requested-With") 
	AND httpData.headers["X-Requested-With"] EQ "XMLHttpRequest">
	
	<!--- disable any layouts if request is AJAX driven --->
	<cfset request.layout = false>
	
</cfif>

<!--- output what the framework already has as a view --->
<cfoutput>#body#</cfoutput>