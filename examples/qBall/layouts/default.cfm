<cfparam name="session.auth.isloggedin" default="false">
<cfparam name="session.auth.username" default="Guest">
<cfparam name="rc.pagetitle" default="QBall">
<cfoutput>
<!DOCTYPE html>
<html>
<head>
<title>#rc.pagetitle#</title>
<link rel="stylesheet" href="css/style.css" type="text/css" />
</head>
<body>
<div id="header">
<a href="index.cfm">Home</a> -
<a href="#buildUrl('question.list')#">Questions</a> -
<cfif not session.auth.isloggedin>
<a href="#buildUrl('user.login')#">Login/Register</a>
<cfelse>
<a href="#buildUrl('question.new')#">Ask a Question</a> -
<a href="#buildUrl('user.logout')#">Logout</a> - Welcome, #session.auth.username#
</cfif>
</div>

<div id="body">
<cfif structKeyExists(rc, "errors")>
    <cfdump var="#rc.errors#"><br>
</cfif>
#body#
</div>

</body>
</html>
</cfoutput>

<!--- Used while I was debugging, will make it an option later so I can toggle an app var and show this
<cfif 0>
<br/><br/><br/>
<cfdump var="#rc#" label="RC" expand="false">
</cfif>
--->
