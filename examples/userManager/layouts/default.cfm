<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>User Manager</title>
<link rel="stylesheet" type="text/css" href="assets/css/styles.css" />
</head>
<body>

<div id="container">
	
	<h1>User Manager</h1>
	
	<ul class="nav horizontal clear">
		<li><a href="index.cfm">Home</a></li>
		<li><a href="index.cfm?action=user.list" title="View the list of users">Users</a></li>
		<li><a href="index.cfm?action=user.form" title="Fill out form to add new user">Add User</a></li>
		<li><a href="index.cfm?reload=true" title="Resets framework cache">Reload</a></li>
	</ul>
	
	<br />
	
	<div id="primary">
		<cfoutput>#body#</cfoutput>
	</div>
	
</div>

</body>
</html>