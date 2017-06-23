<ul>
  <cfoutput query="rc.subsystems">
    <li>
	  <a href="examples/subsystems/#rc.subsystems.name#/">#rc.subsystems.name#</a>
    </li>
  </cfoutput>
	<cfoutput query="rc.files">
		<!--- updated to omit common/home which are part of the subsystems demo --->
		<cfif rc.files.type is 'dir' and left(rc.files.name,1) is not '.' and
          rc.files.name is not 'layouts' and rc.files.name is not 'views' and
          rc.files.name is not 'subsystems'>
			<li>
				<a href="examples/#rc.files.name#/">#rc.files.name#</a>
				<cfswitch expression="#rc.files.name#">
          <cfcase value="mustache">
            - requires Java 8!
          </cfcase>
          <cfcase value="remote">
					  - will not work with a non-empty context root!
          </cfcase>
          <cfcase value="todos">
            - requires /examples/todos/index.cfm/* as a wildcard pattern for Tomcat!
          </cfcase>
        </cfswitch>
			</li>
		</cfif>
	</cfoutput>
	<li><a href="examples/index.cfm">Examples as subsystems</a> - reuses some of the examples "as-is".</li>
</ul>
