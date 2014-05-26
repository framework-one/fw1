<cfoutput>
	<cfform name="userForm" id="userForm" method="post" action="#buildUrl('main.change')#">
		<cfinput type="hidden" name="id" value="#rc.id#">
		<table cellpadding="0" cellspacing="0">
			<tr>
				<th colspan="2">Change Password</th>
			</tr>
			<tr>
				<td><strong><label for="currentPassword" class="label">Current Password:</label></strong></td>
				<td><cfinput type="password" name="currentPassword" id="currentPassword" size="25" required="yes" message="Please enter your current password" /></td>
			</tr>
			<tr>
				<td><strong><label for="newPassword" class="label">New Password:</label></strong></td>
				<td><cfinput type="password" name="newPassword" id="newPassword" size="25" required="yes" message="Please enter your new password" /></td>
			</tr>
			<tr>
				<td><strong><label for="retypePassword" class="label">Retype New Password:</label></strong></td>
				<td><cfinput type="password" name="retypePassword" id="retypePassword" size="25" required="yes" message="Please retype your new password" /></td>
			</tr>
		</table>
		<input type="submit" value="Change Password">
	</cfform>

	<p><strong>Your New Password:</strong></p>
	<ul>
		<li>Can not match your current password</li>
		<li>Must be at least 8 characters long</li>
		<li>Must contain at least 1 letter</li>
		<li>Must contain at least 1 number or special character</li>
		<li>Is case sensitive</li>
		<li>Can not contain your email address</li>
	</ul>
</cfoutput>
