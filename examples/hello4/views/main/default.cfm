<cfoutput>
	<p>#rc.greeting# #rc.name##rc.punctuation#</p>
	<p>Run again <a href="#buildURL( action = 'main.default', queryString = 'name=FW/1' )#">with a name</a>?</p>
</cfoutput>