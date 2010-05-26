<cfoutput>
	<p>This example demonstrates that request context data can be preserved across a redirect.</p>
	<p>Hello #rc.name#!</p>
	<cfdump var="#rc#" />
	<p>When you submit this form, it will redirect back to this default view. The dump
		will show the submitted form fields have all been preserved in the request context.
		Note that the form field action is overwritten by the URL variable: preserved data
		is just the default values for the next request's context and is overwritten by URL
		and form data (and URL data is overwritten by form data).
		Note also that session management must be enabled in Application.cfc!</p>
	<form action="" method="get">
		<input type="hidden" name="action" value="#getFullyQualifiedAction('main.submit')#" />
		Name: <input type="text" name="name" /><br />
		<input type="submit" name="submit" value="Submit" />
	</form>
	<p>Use buildURL() queryString to the same effect: <a href="#buildURL( action='main.submit', queryString='name=QueryString' )#">Pass name via QueryString</a></p>
	<p>Use buildURL() shortcut to the same effect: <a href="#buildURL( 'main.submit?name=Shortcut' )#">Pass name via Shortcut</a></p>
</cfoutput>