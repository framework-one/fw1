<html>
	<head>
		<!--- title set by a view - there is no default --->
		<title>FW/1 Skeleton - <cfoutput>#rc.title#</cfoutput></title>
	</head>
	<body>
		<h1>FW/1 Default Layout</h1>
		<cfoutput>#body#</cfoutput>	<!--- body is result of views --->
		<p style="font-size: small;">
			Powered by FW/1 version <cfoutput>#variables.framework.version#</cfoutput>.<br />
			This request took <cfoutput>#getTickCount() - rc.startTime#</cfoutput>ms.
		</p>
	</body>
</html>