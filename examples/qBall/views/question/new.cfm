<cfset rc.pagetitle = "Ask a Question">
<cfparam name="rc.title" default="">
<cfparam name="rc.text" default="">

<h1>Ask a Question</h1>

<cfif structKeyExists(rc, "errors")>
	<p>
	<b>Your question coult not be posted due to the following error(s):</b><br/>
	<ul>
	<cfloop index="e" array="#rc.errors#">
		<cfoutput><li>#e#</li></cfoutput>
	</cfloop>
	</ul>
</cfif>

<cfoutput>
<form action="?#framework.action#=question.post" method="post">
<p>
Give your question a simple, appropriate title.<br/>
<input type="text" name="title" value="#rc.title#" size="100">
</p>

<p>
Now enter the text of your question. Be as clear as possible.<br/>
<textarea name="text" cols="50" rows="10">#rc.text#</textarea>
</p>

<p>
<input type="submit" value="Post Question">
</p>
</form>
</cfoutput>
