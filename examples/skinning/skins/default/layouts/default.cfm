<h1>This is the default layout.</h1>
<cfoutput>
	#body#
	<p>Go to 
		<a href="<cfoutput>#buildUrl( 'main' )#</cfoutput>">default page</a> |
		<a href="<cfoutput>#buildUrl( 'main.second' )#</cfoutput>">second page</a>.</p>
	<p>Select skin:
		<a href="#buildUrl( request.action )#&skin=blue">blue</a> |
		<a href="#buildUrl( request.action )#&skin=green">green</a> |
		<a href="#buildUrl( request.action )#&skin=default">default</a>.</p>
</cfoutput>