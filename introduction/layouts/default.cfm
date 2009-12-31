<html>
	<head>
		<title>FW/1 - Framework One</title>
		<base href="<cfoutput>#getDirectoryFromPath( CGI.SCRIPT_NAME )#</cfoutput>" />
		<link rel="stylesheet" type="text/css" href="css/fw1.css" />
	</head>
	<body>
		<div class="wrap">
			<div class="page">
				<cfoutput>#body#</cfoutput>
			</div>
			<div class="footer">
				<a href="http://fw1.riaforge.org/">FW/1</a> is copyright (c) 2009 Sean Corfield, Ryan Cogswell - 
				<a href="http://www.apache.org/licenses/LICENSE-2.0">Licensed under the Apache License, Version 2.0</a>
			</div>
		</div>
	</body>
</html>