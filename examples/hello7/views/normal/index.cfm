<cfoutput>
	<p>Hello FW/1!</p>
	<cfdump var="#rc.lifecycle#"/>
	<p>Run again <a href="#buildURL( action = 'main.default', queryString = 'donotcatchexception' )#">without catching that exception</a>?</p>
	<p>Run again <a href="#buildURL( action = 'main.default' )#">and catch the exception</a>?</p>
</cfoutput>