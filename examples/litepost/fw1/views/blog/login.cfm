<cfsilent>
	<cfset rc.title = "LitePost - Login" />
	<cfparam name="rc.message" default="" />
</cfsilent>

<cfoutput>
	<h1>Please Log In</h1>
		
	<cfif len(rc.message)>
		<p style="color:red;font-weight:bold;" align="center">#rc.message#</p>
	</cfif>
	
	<form action="?#framework.action#=blog.doLogin" method="post">
	  	<label>Username<br />
	  	<input name="userName" type="text" maxlength="30" />
		</label>
		<label>Password<br />
		<input name="password" type="password" maxlength="30" />
		</label>
		<input type="submit" name="submit" value="Log In" class="adminbutton" />
	</form>
</cfoutput>