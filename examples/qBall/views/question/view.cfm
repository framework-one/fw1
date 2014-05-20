<cfset rc.pagetitle = rc.question.getTitle()>
<cfset answers = rc.question.getAnswers()>

<cfoutput>
<h1>#rc.question.getTitle()#</h1>
<p>
Asked by #rc.question.getUser().getUsername()# on #dateFormat(rc.question.getCreated(), "mmmm d, yyyy")# at #timeFormat(rc.question.getCreated(), "h:mm tt")#
</p>

#paragraphFormat(rc.question.getText())#

<h2>Answers</h2>

<cfif arrayLen(answers) is 0>
	<p>
	This question has no answers yet!
	</p>
<cfelse>
	<cfset counter = 0><!--- used to toggle styles --->
	<cfloop index="answer" array="#answers#">
		<cfset counter++>
		<cfif answer.getSelectedAnswer()>
			<cfset myClass = "selectedanswer">
		<cfelseif counter mod 2 is 1>
			<cfset myClass = "answerOdd">
		<cfelse>
			<cfset myClass = "answer">
		</cfif>
		<div class="#myClass#">
		<b>Answer posted by #answer.getUser().getUsername()# on
		#dateFormat(answer.getCreated(), "mmmm d, yyyy")# at #timeFormat(answer.getCreated(), "h:mm tt")#</b></br>

		<cfif session.auth.isloggedin>
			<a href="?#framework.action#=question.voteanswerdown&answerid=#answer.getId()#&questionid=#rc.question.getId()#"><img src="images/heart_delete.png" title="Vote Down" border="0"></a>
		</cfif>
		#arrayLen(answer.getDisapprovers())# Votes Against /
		<cfif session.auth.isloggedin>
			<a href="?#framework.action#=question.voteanswerup&answerid=#answer.getId()#&questionid=#rc.question.getId()#"><img src="images/heart_add.png" title="Vote Up" border="0"></a>
		</cfif>
		#arrayLen(answer.getApprovers())# Votes For

		<br/><br/>

		#paragraphFormat(answer.getText())#

		<cfif not answer.getSelectedAnswer() and session.auth.isLoggedIn and (rc.question.getUser().getId() is session.auth.userId)>
		<p align="right">
		<a href="?#framework.action#=question.selectanswer&answerid=#answer.getId()#&questionid=#rc.question.getId()#">Mark this as the best answer.</a>
		</p>
		</cfif>
		</div>
	</cfloop>
</cfif>

<cfif session.auth.isloggedin>
	<form action="?#framework.action#=question.postanswer" method="post">
	<input type="hidden" name="questionid" value="#rc.question.getId()#">
	<b>Post your Answer:</b><br/>
	<textarea name="answer" style="width:100%;height:200px"></textarea><br/>
	<input type="submit" value="Post Answer">
	</form>
<cfelse>
	Please <a href="?#framework.action#=user.login">login or register</a> to post your own answer.
</cfif>
</cfoutput>
