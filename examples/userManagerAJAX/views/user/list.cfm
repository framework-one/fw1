<cfset local.users = rc.data>

<cfoutput>
<table border="0" cellspacing="0">
	<col width="40" />
	<thead>
		<tr>
			<th>Id</th>
			<th>Name</th>
			<th>Email</th>
			<th>Department</th>
			<th>Delete</th>
		</tr>
	</thead>
	<tbody>
		<cfif structCount(local.users) EQ 0>
			<tr><td colspan="5">No users exist but <a href="index.cfm?action=user.form">new ones can be added</a>.</td></tr>
		</cfif>
		<cfloop collection="#local.users#" item="local.id">
			
			<cfset local.user = local.users[local.id]>
			
			<tr>
				<td><a href="index.cfm?action=user.form&id=#local.id#">#local.id#</a></td>
				<td><a href="index.cfm?action=user.form&id=#local.id#">#local.user.getFirstName()# #local.user.getLastName()#</a></td>
				<td>#local.user.getEmail()#</td>
				<td>#local.user.getDepartment().getName()#</td>
				<td><a href="index.cfm?action=user.delete&id=#local.id#">DELETE</a></td>
			</tr>
		</cfloop>
	</tbody>
</table>
</cfoutput>