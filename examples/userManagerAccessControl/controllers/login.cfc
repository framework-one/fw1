<cfcomponent>
	<cfset variables.fw = '' />
	<cffunction name="init" access="public" returntype="void">
		<cfargument name="fw" type="any" required="yes" />
		<cfset variables.fw = arguments.fw />
	</cffunction>

	<cffunction name="setUserService" access="public" output="false" returntype="void">
		<cfargument name="userService" type="any" required="true" />
		<cfset variables.userService = arguments.userService />
	</cffunction>
	<cffunction name="getUserService" access="public" output="false" returntype="any">
		<cfreturn variables.userService />
	</cffunction>

	<cffunction name="before" access="public" output="no" returntype="void">
		<cfargument name="rc" type="struct" required="yes" />
		<cfif session.auth.isLoggedIn and variables.fw.getItem() is not 'logout'>
			<cfset variables.fw.redirect('main') />
		</cfif>
	</cffunction>
	
	<cffunction name="login" access="public" returntype="void">
		<cfargument name="rc" type="struct" required="yes" />

		<cfset var userValid = 0 />
		<cfset var userService = getUserService() />
		<cfset var user = '' />

		<!--- if the form variables do not exist, redirect to the login form --->
		<cfif not structkeyexists(rc,'email') or not structkeyexists(rc,'password')>
			<cfset variables.fw.redirect('login') />
		</cfif>

		<!--- look up the user's record by the email address --->
		<cfset user = userService.getByEmail(rc.email) />

		<!--- if the user object contains a record then the username was legit, lets look at the passwords --->
		<cfif user.getId()>
			<cfset userValid = userService.validatePassword(user,rc.password) />
		</cfif>

		<!--- if the login credentials failed the test, set a message and redirect to the login form --->
		<cfif not userValid>
			<cfset rc.message = ['Invalid Username or Password'] />
			<cfset variables.fw.redirect('login','message') />
		</cfif>

		<!--- since the user is valid, set session variables --->
		<cfset session.auth.isLoggedIn = true />
		<cfset session.auth.fullname = user.getFirstName() & ' ' & user.getLastName() />
		<cfset session.auth.user = user />

		<cfset variables.fw.redirect('main') />
	</cffunction>

	<cffunction name="logout" access="public" returntype="void">
		<cfargument name="rc" type="struct" required="yes" />
		<!--- reset the session variables --->
		<cfset session.auth.isLoggedIn = false />
		<cfset session.auth.fullname = 'Guest' />
		<cfset structdelete(session.auth,'user') />
		<cfset rc.message = ['You have safely logged out'] />
		<cfset variables.fw.redirect('login','message') />
	</cffunction>

</cfcomponent>