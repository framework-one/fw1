<cfoutput>
	<h2>Hello FW/1!</h2>
	<p>This demonstrates the lifecycle in the presence of abortController() and setupView().</p>
	<cfdump var="#rc.lifecycle#"/>
	<p>Run again <a href="#buildURL( action = 'main.default', queryString = 'donotcatchexception' )#">without catching that exception</a>?</p>
	<p>Run again <a href="#buildURL( action = 'main.default' )#">and catch the exception</a>?</p>
</cfoutput>