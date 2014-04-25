<cfparam name="rc.questions" default="#structNew()#">
<cfoutput>
<h1>Welcome to QBall</h1>
<p>QBall is an question and answer application. Users can write questions or
respond to others. Users can also rate answers up and down.</p>

<cfif session.auth.isloggedin>
    <p>
        <a href="#buildUrl('question.new')#">Ask a Question!</a>
    </p>
<cfelse>
    <p>
        To ask your own question (or respond to others), please
        <a href="#buildUrl('user.login')#">login or register</a>.
    </p>
</cfif>

<h2>Recent Questions</h2>

<cfif rc.questions.count gt 0>
    <cfloop index="q" array="#rc.questions.data#">
        <p>
        <a href="?#framework.action#=question.view&questionid=#q.getId()#">#q.getTitle()#</a>
        <cfif q.getAnswered()>
            <b>Answered</b>
        </cfif>
        <br/>
            Asked by #q.getUser().getUsername()# on
            #dateFormat(q.getCreated(), "mmmm d, yyyy")# at
            #timeFormat(q.getCreated(), "h:mm tt")#
        </p>
    </cfloop>
<cfelse>
    <p>
        There are no questions currently.
    </p>
</cfif>
</cfoutput>
