<cfset local.user = rc.user>
<cfset local.depts = rc.departments>
<cfset local.roles = rc.roles>

<h3>User Info</h3>

<cfoutput>
<form class="familiar medium" method="post" action="index.cfm?action=user.save">

	<input type="hidden" name="id" value="#local.user.getId()#">

	<div class="field">
		<label for="firstName" class="label">First Name:</label>
		<input type="text" name="firstName" id="firstName" value="#local.user.getFirstName()#">
	</div>

	<div class="field">
		<label for="lastName" class="label">Last Name:</label>
		<input type="text" name="lastName" id="lastName" value="#local.user.getLastName()#">
	</div>

	<div class="field">
		<label for="email" class="label">Email:</label>
		<input type="text" name="email" id="email" value="#local.user.getEmail()#">
	</div>

	<div class="field">
		<label for="departmentId" class="label">Department:</label>
		<select name="departmentId" id="departmentId">
			<cfloop collection="#local.depts#" item="local.id">

				<cfset local.dept = local.depts[local.id]>

				<!--- when editing a user we need to set the dept that user currently has --->
				<cfif local.id EQ local.user.getDepartmentId()>
					<option value="#local.id#" selected="selected">#local.dept.getName()#</option>
				<cfelse>
					<option value="#local.id#">#local.dept.getName()#</option>
				</cfif>
            </cfloop>
		</select>
	</div>

	<div class="field">
		<label for="roleId" class="label">Role:</label>
		<select name="roleId" id="roleId">
			<cfloop collection="#local.roles#" item="local.id">

				<cfset local.role = local.roles[local.id]>

				<!--- when editing a user we need to set the role that user currently has --->
				<cfif local.id EQ local.user.getRoleId()>
					<option value="#local.id#" selected="selected">#local.role.getName()#</option>
				<cfelse>
					<option value="#local.id#">#local.role.getName()#</option>
				</cfif>
      </cfloop>
		</select>
	</div>

	<cfif not local.user.getId()>
	<div class="field">
		<label for="password" class="label">Password:</label>
		<input type="text" name="password" id="password">
	</div>
	</cfif>

	<div class="control">
		<input type="submit" value="Save User">
	</div>

</form>
</cfoutput>