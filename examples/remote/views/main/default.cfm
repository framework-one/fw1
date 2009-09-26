<h1>Test Remote Method Call Through FW/1</h1>
<p><a href="remote/Test.cfc?method=test" target="_blank">Simple in browser invocation</a>!</p>
<cftry>
	<cfset ws = createObject( "webservice", "http://#CGI.SERVER_NAME#:#CGI.SERVER_PORT#/examples/remote/remote/Test.cfc?WSDL") />
	<cfoutput>
		<p>Web Service call: #ws.test()#</p>
	</cfoutput>
<cfcatch type="any">
	<p>Web Service call failed :(</p>
	<cfdump var="#cfcatch#" />
</cfcatch>
</cftry>
<p><a href="fw1.html" target="_blank">Try the Flex test</a>!</p>