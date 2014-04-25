<cfset rc.pagetitle = "All Questions">
<!--- rc.data is a struct containing the total num of questions and our page --->
<cfset questions = rc.result.data>
<cfset totalquestions = rc.result.count>
<cfparam name="rc.start" default="1">


<h1>All Questions</h1>

<cfif totalquestions is 0>
    <p>
    Sorry, there are no questions!
    </p>
<cfelse>

    <cfif totalquestions gt arrayLen(questions)>
        <cfoutput>
        <p class="pagination">
        <cfif rc.start neq 1>
            <a href="?#framework.action#=question.list&start=#rc.start-10#">Previous</a>
        <cfelse>
            Previous
        </cfif>
        -
        <cfif (rc.start + 9) lt totalquestions>
            <a href="?#framework.action#=question.list&start=#rc.start+10#">Next</a>
        <cfelse>
            Next
        </cfif>
        </p>
        </cfoutput>
    </cfif>

    <cfloop index="q" array="#questions#">
        <p>
        <cfoutput>
        <a href="?#framework.action#=question.view&questionid=#q.getId()#">#q.getTitle()#</a> <cfif q.getAnswered()><b>Answered</b></cfif><br/>
        Asked by #q.getUser().getUsername()# on #dateFormat(q.getCreated(), "mmmm d, yyyy")# at #timeFormat(q.getCreated(), "h:mm tt")#
        </cfoutput>
        </p>
    </cfloop>


</cfif>
