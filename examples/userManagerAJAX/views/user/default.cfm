<!--- give an indication that we have reloaded the application (cleared its cache) --->
<cfif structKeyExists(rc, "reload")>
	
	<p><strong>The framework cache (and application scope) have been reset.</strong></p>
	
</cfif>

<p><cfoutput>#rc.message#</cfoutput></p>

<p>This version of the User Manager demo is powered by jQuery to 
demonstrate an accessible application that isn't dependent on JavaScript. 
If JavaScript is disabled the application will function as a normal 
multi-page app, meaning click a link it loads a whole new page. Although 
if JavaScript is enabled the application works as a single page app 
(the default intended behavior) where the page doesn't refresh and any 
new content loaded is added dynamically to the DOM. All reusing the same 
views and just disabling layouts on any AJAX calls.</p>