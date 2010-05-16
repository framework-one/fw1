<cfoutput>
	<cfform name="login" id="login" action="#buildURL('login.login')#" method="post">
		<table cellpadding="0" cellspacing="0">
			<tr>
				<th colspan="2">Login</th>
			</tr>
			<tr>
				<td><strong><label for="email" class="label">Email:</label></strong></td>
				<td><cfinput type="text" name="email" id="email" size="50" maxlength="100" required="yes" message="Please enter your email address" /></td>
			</tr>
			<tr>
				<td><strong><label for="password" class="label">Password:</label></strong></td>
				<td><cfinput type="password" name="password" id="password" size="25" required="yes" message="Please enter your password" /></td>
			</tr>
		</table>
		<input type="submit" value="Login">
	</cfform>
</cfoutput>
