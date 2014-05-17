<cfcomponent displayname="UserService" output="false">

	<cfset variables.users = structNew()>

	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="departmentService" type="any" required="true" />
		<cfargument name="roleService" type="any" required="true" />

		<cfscript>
		var user = "";
		var deptService = arguments.departmentService;
		var passwordHashSalt = '';

		setDepartmentService(arguments.departmentService);
		setRoleService(arguments.roleService);

		// since services are cached, user data well be persisted
		// ideally, this would be saved elsewhere, e.g. database

		// FIRST
		user = new();
		user.setId("1");
		user.setFirstName("Admin");
		user.setLastName("User");
		user.setEmail("admin@mysite.com");
		user.setDepartmentId("1");
		user.setDepartment(deptService.get("1"));
		user.setRoleId("1");
		user.setRole(arguments.roleService.get("1"));
		// set the password.  typically the hash and salt would be in a database.
		// avoid plain text passwords in files or the database
		passwordHashSalt = hashPassword('admin');
		user.setPasswordHash(passwordHashSalt.hash);
		user.setPasswordSalt(passwordHashSalt.salt);

		variables.users[user.getId()] = user;

		// SECOND
		user = new();
		user.setId("2");
		user.setFirstName("Larry");
		user.setLastName("Stooge");
		user.setEmail("larry@stooges.com");
		user.setDepartmentId("2");
		user.setDepartment(deptService.get("2"));
		user.setRoleId("2");
		user.setRole(arguments.roleService.get("2"));
		passwordHashSalt = hashPassword('larryrulz');
		user.setPasswordHash(passwordHashSalt.hash);
		user.setPasswordSalt(passwordHashSalt.salt);

		variables.users[user.getId()] = user;

		// THIRD
		user = new();
		user.setId("3");
		user.setFirstName("Moe");
		user.setLastName("Stooge");
		user.setEmail("moe@stooges.com");
		user.setDepartmentId("3");
		user.setDepartment(deptService.get("3"));
		user.setRoleId("2");
		user.setRole(arguments.roleService.get("2"));
		passwordHashSalt = hashPassword('moerulz');
		user.setPasswordHash(passwordHashSalt.hash);
		user.setPasswordSalt(passwordHashSalt.salt);

		variables.users[user.getId()] = user;

		// BEN
		variables.nextid = 4;
		</cfscript>

		<cfreturn this>
	</cffunction>

	<cffunction name="setDepartmentService" access="public" output="false">
		<cfargument name="departmentService" type="any" required="true" />
		<cfset variables.departmentService = arguments.departmentService />
	</cffunction>
	<cffunction name="getDepartmentService" access="public" returntype="any" output="false">
		<cfreturn variables.departmentService />
	</cffunction>

	<cffunction name="setRoleService" access="public" output="false">
		<cfargument name="roleService" type="any" required="true" />
		<cfset variables.roleService = arguments.roleService />
	</cffunction>
	<cffunction name="getRoleService" access="public" returntype="any" output="false">
		<cfreturn variables.roleService />
	</cffunction>

	<cffunction name="delete" access="public" output="false" returntype="boolean">
		<cfargument name="id" type="string" required="true">

		<cfreturn structDelete(variables.users, arguments.id)>
	</cffunction>

	<cffunction name="get" access="public" output="false" returntype="any">
		<cfargument name="id" type="string" required="false" default="">

		<cfset var result = "">

		<cfif len(id) AND structKeyExists(variables.users, id)>
			<cfset result = variables.users[id]>
		<cfelse>
			<cfset result = new()>
		</cfif>

		<cfreturn result>
	</cffunction>

	<cffunction name="getByEmail" access="public" returntype="any">
		<cfargument name="email" type="string" required="false" default="">

		<cfset var result = "">
		<cfset var userid = "">
		<cfset var user = "">

		<cfif len(email)>
			<!--- loop through the users, looking for a matching email address --->
			<cfloop collection="#variables.users#" item="userid">
				<cfset user = variables.users[userid] />
				<cfif not comparenocase(arguments.email,user.getEmail())>
					<cfset result = user />
				</cfif>
			</cfloop>
		</cfif>

		<!--- if there is no user with a matching email address, return a blank user --->
		<cfif not isstruct(result)>
			<cfset result = new()>
		</cfif>

		<cfreturn result>
	</cffunction>

	<cffunction name="list" access="public" output="false" returntype="struct">
		<cfreturn variables.users>
    </cffunction>

	<cffunction name="new" access="public" output="false" returntype="any">
		<cfreturn createObject("component", "userManager.model.User").init()>
	</cffunction>

	<cffunction name="validate" access="public" output="false" returntype="Array">
		<cfargument name="user" type="any" required="true" />
		<cfargument name="firstName" type="string" required="false" default="" />
		<cfargument name="lastName" type="string" required="false" default="" />
		<cfargument name="email" type="string" required="false" default="" />
		<cfargument name="departmentId" type="string" required="false" default="" />
		<cfargument name="roleId" type="string" required="false" default="" />
		<cfargument name="password" type="string" required="false" default="" />
		<cfset var aErrors = arrayNew(1) />
		<!--- check to see if a user exists with the email address --->
		<cfset var userByEmail = getByEmail(arguments.email) />
		<!--- check to see if the department selected matches a department record --->
		<cfset var department = getDepartmentService().get(arguments.departmentId) />
		<!--- check to see if the role selected matches a role record --->
		<cfset var role = getRoleService().get(arguments.roleId) />

		<!--- if the user is new, make sure there is a password --->
		<cfif not arguments.user.getId() and not len(arguments.password)>
			<cfset arrayAppend(aErrors,"Please enter a password for the user") />
		<!--- make sure the password is valid --->
		<cfelseif len(arguments.password)>
			<cfset aErrors = checkPassword(user=arguments.user,
				newPassword=arguments.password,
				retypePassword=arguments.password) />
		</cfif>

		<!--- first name is required --->
		<cfif not len(arguments.user.getFirstName()) and not len(arguments.firstName)>
			<cfset arrayAppend(aErrors,"Please enter the user's first name") />
		</cfif>

		<!--- last name is required --->
		<cfif not len(arguments.user.getLastName()) and not len(arguments.lastName)>
			<cfset arrayAppend(aErrors,"Please enter the user's last name") />
		</cfif>

		<!--- email address is required --->
		<cfif not len(arguments.user.getEmail()) and not len(arguments.email)>
			<cfset arrayAppend(aErrors,"Please enter the user's email address") />
		<!--- verify the email is a valid format --->
		<cfelseif len(arguments.email) and not isEmail(arguments.email)>
			<cfset arrayAppend(aErrors,"Please enter a valid email address") />
		<!--- verify the email address is unique for this user --->
		<cfelseif len(arguments.email) and compare(arguments.email,arguments.user.getEmail()) and userByEmail.getId()>
			<cfset arrayAppend(aErrors,"A user already exists with this email address, please enter a new address.") />
		</cfif>

		<!--- department id is required, must be numeric and match a department record --->
		<cfif not len(arguments.departmentId) or not isnumeric(arguments.departmentId) or not department.getId()>
			<cfset arrayAppend(aErrors,"Please select a department") />
		</cfif>

		<!--- role id is required, must be numeric and match a role record --->
		<cfif not len(arguments.roleId) or not isnumeric(arguments.roleId) or not role.getId()>
			<cfset arrayAppend(aErrors,"Please select a role") />
		</cfif>

		<cfreturn aErrors />
	</cffunction>

	<cffunction name="save" access="public" output="false" returntype="void">
		<cfargument name="user" type="any" required="true">

		<cfset var newId = 0>

		<!--- since we have an id we are updating a user --->
		<cfif arguments.user.getId()>
			<cfset variables.users[arguments.user.getId()] = arguments.user>
		<cfelse>
			<!--- otherwise a new user is being saved --->
			<!--- BEN --->
			<cflock type="exclusive" name="setNextID" timeout="10" throwontimeout="false">
				<cfset newId = variables.nextid>
				<cfset variables.nextid = variables.nextid + 1>
			</cflock>
			<!--- END BEN --->

			<cfset arguments.user.setId(newId)>

			<cfset variables.users[newId] = arguments.user>
		</cfif>
	</cffunction>

<!---
security functions were adapted from Jason Dean's security series
http://www.12robots.com/index.cfm/2008/5/13/A-Simple-Password-Strength-Function-Security-Series-4.1
http://www.12robots.com/index.cfm/2008/5/29/Salting-and-Hashing-Code-Example--Security-Series-44
http://www.12robots.com/index.cfm/2008/6/2/User-Login-with-Salted-and-Hashed-passwords--Security-Series-45
--->

	<cffunction name="hashPassword" access="public" output="false" returntype="struct">
		<cfargument name="password" type="string" required="true" hint="Pass in password" />
		<!--- At this point the function assumes that you have already validated the
			password as meeting application requirements --->
		<cfset var returnVar = structNew() />
		<cfset var passwordHash = "" />

		<!--- Salt the password --->
		<cfset var salt = createUUID() />

		<cfset passwordHash = hash(arguments.password & salt, 'SHA-512') />

		<cfset returnVar.hash = passwordHash />
		<cfset returnVar.salt = salt />

		<cfreturn returnVar />
	</cffunction>

	<cffunction name="validatePassword" access="public" output="no" returntype="boolean">
		<cfargument name="user" required="yes" type="any" />
		<cfargument name="password" required="yes" type="string" />
		<cfset var validPass = false />

		<!--- Set the input hash by concatenating the password that was passed in to the salt
			and hashing it with the same hash function as when it was stored. --->
		<cfset var inputHash = hash(trim(arguments.password) & trim(arguments.user.getPasswordSalt()), 'SHA-512') />

		<!--- Compare the inputHash with the hash we pulled from the db if they match,
			then the correct password was passed in --->
		<cfif not compare(inputHash, arguments.user.getPasswordHash())>
			<cfset validPass = true />
		</cfif>

		<cfreturn validPass />
	</cffunction>

	<cffunction name="checkPassword" access="public" output="no" returntype="array"
    	hint="I check password strength and determine if it is up to snuff, I return an array of error messages">
		<cfargument name="user" type="any" required="true">
		<cfargument name="currentPassword" type="string" required="no" default=""
			hint="Send in current user's password for validation when user is changing password" />
		<cfargument name="newPassword" required="no" default="" type="string"
			hint="Send in password1 as a string, default is a blank string, which will fail" />
		<cfargument name="retypePassword" required="no" default="" type="string"
			hint="Send in password2 as a string, default is a blank string, which will fail" />
		<cfscript>
		// Initialize return variable
		var aErrors = arrayNew(1);
		var inputHash = '';
		var count = 0;

		// if the password fields to not have values, add an error and return
		if (not len(arguments.newPassword) or not len(arguments.retypePassword)) {
			arrayAppend(aErrors, "Please fill out all form fields");
			return aErrors;
		}

		if (len(arguments.currentPassword) and isObject(user)) {
			// If the user is changing their password, compare the current password to the saved hash
			inputHash = hash(trim(arguments.currentPassword) & trim(user.getPasswordSalt()), 'SHA-512');

			/* Compare the inputHash with the hash in the user object. if they do not match,
				then the correct password was not passed in */
			if (not compare(inputHash, user.getPasswordHash()) IS 0) {
				arrayAppend(aErrors, "Your current password does not match the current password entered");
				// Return now, there is no point testing further
				return aErrors;
			}

			// Compare the current password to the new password, if they match add an error
			if (compare(arguments.currentPassword, arguments.newPassword) IS 0)
				arrayAppend(aErrors, "The new password can not match your current password");
		}

		// Check the password rules
		// *** to change the strength of the password required, uncomment as needed

		// Check to see if the two passwords match
		if (not compare(arguments.newPassword, arguments.retypePassword) IS 0) {
			arrayAppend(aErrors, "The new passwords you entered do not match");
			// Return now, there is no point testing further
			return aErrors;
		}

		// If the password is more than X and less than Y, add an error.
		if (len(arguments.newPassword) LT 8)// OR Len(arguments.newPassword) GT 25
			arrayAppend(aErrors, "Your password must be at least 8 characters long");// between 8 and 25

		// Check for atleast 1 uppercase or lowercase letter
		/* if (NOT REFind('[A-Z]+', arguments.newPassword) AND NOT REFind('[a-z]+', arguments.newPassword))
			ArrayAppend(aErrors, "Your password must contain at least 1 letter"); */

		// check for at least 1 letter
		if (reFind('[A-Z]+',arguments.newPassword))
			count++;
		if (reFind('[a-z]+', arguments.newPassword))
			count++;
		if (not count)
			arrayAppend(aErrors, "Your password must contain at least 1 letter");

		// Check for at least 1 uppercase letter
		/*if (NOT REFind('[A-Z]+', arguments.newPassword))
			ArrayAppend(aErrors, "Your password must contain at least 1 uppercase letter");*/

		// Check for at least 1 lowercase letter
		/*if (NOT REFind('[a-z]+', arguments.newPassword))
			ArrayAppend(aErrors, "Your password must contain at least 1 lowercase letter");*/

		// check for at least 1 number or special character
		count = 0;
		if (reFind('[1-9]+', arguments.newPassword))
			count++;
		if (reFind("[;|:|@|!|$|##|%|^|&|*|(|)|_|-|+|=|\'|\\|\||{|}|?|/|,|.]+", arguments.newPassword))
			count++;
		if (not count)
			arrayAppend(aErrors, "Your password must contain at least 1 number or special character");

		// Check for at least 1 numeral
		/*if (NOT REFind('[1-9]+', arguments.newPassword))
			ArrayAppend(aErrors, "Your password must contain at least 1 number");*/

		// Check for one of the predfined special characters, you can add more by seperating each character with a pipe(|)
		/* if (NOT REFind("[;|:|@|!|$|##|%|^|&|*|(|)|_|-|+|=|\'|\\|\||{|}|?|/|,|.]+", arguments.newPassword))
			ArrayAppend(aErrors, "Your password must contain at least 1 special character"); */

		// Check to see if the password contains the username
		if (len(user.getEmail()) and arguments.newPassword CONTAINS user.getEmail())
			arrayAppend(aErrors, "Your password cannot contain your email address");

		// Check to see if password is a date
		if (isDate(arguments.newPassword))
			arrayAppend(aErrors, "Your password cannot be a date");

		// Make sure password contains no spaces
		if (arguments.newPassword CONTAINS " ")
			arrayAppend(aErrors, "Your password cannot contain spaces");
		</cfscript>

		<!--- return the array of errors --->
		<cfreturn aErrors />
	</cffunction>

<!--- cflib.org --->

<cfscript>
/**
* Tests passed value to see if it is a valid e-mail address (supports subdomain nesting and new top-level domains).
* Update by David Kearns to support '
* SBrown@xacting.com pointing out regex still wasn't accepting ' correctly.
* Should support + gmail style addresses now.
* More TLDs
* Version 4 by P Farrel, supports limits on u/h
* Added mobi
* v6 more tlds
*
* @param str      The string to check. (Required)
* @return Returns a boolean.
* @author Jeff Guillaume (SBrown@xacting.comjeff@kazoomis.com)
* @version 7, May 8, 2009
*/
function isEmail(str) {
return (REFindNoCase("^['_a-z0-9-\+]+(\.['_a-z0-9-\+]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*\.(([a-z]{2,3})|(aero|asia|biz|cat|coop|info|museum|name|jobs|post|pro|tel|travel|mobi))$",
arguments.str) AND len(listGetAt(arguments.str, 1, "@")) LTE 64 AND
len(listGetAt(arguments.str, 2, "@")) LTE 255) IS 1;
}
</cfscript>

</cfcomponent>