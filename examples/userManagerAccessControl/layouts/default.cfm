<cfparam name="rc.message" default="#arrayNew(1)#">

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>User Manager with Access Control</title>
<link rel="stylesheet" type="text/css" href="assets/css/styles.css" />
</head>
<body>

<div id="container">

	<h1>User Manager with Access Control</h1>

	<ul class="nav horizontal clear">
		<cfif structKeyExists( session, "auth" ) and session.auth.isLoggedIn>
			<li><a href="index.cfm">Home</a></li>
			<cfif session.auth.user.getRoleId() is 1>
				<li><a href="index.cfm?action=user.list" title="View the list of users">Users</a></li>
				<li><a href="index.cfm?action=user.form" title="Fill out form to add new user">Add User</a></li>
			</cfif>
			<li><a href="index.cfm?action=main.password" title="Fill out form to change your password">Change Password</a></li>
			<li><a href="index.cfm?action=login.logout" title="Logout">Logout</a></li>
		<cfelse>
			<li><a href="index.cfm?action=login" title="Login">Login</a></li>
		</cfif>
		<li><a href="index.cfm?reload=true" title="Resets framework cache">Reload</a></li>
	</ul>

	<br />

	<div id="primary">
		<cfoutput>
			<!--- display any messages to the user --->
			<cfif not arrayIsEmpty(rc.message)>
				<cfloop array="#rc.message#" index="msg">
					<p>#msg#</p>
				</cfloop>
			</cfif>

			#body#
		</cfoutput>
	</div>

</div>

</body>
</html>
