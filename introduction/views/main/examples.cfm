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
				<cfif rc.files.name is 'remote' or rc.files.name is 'litepost'>
					- will not work with a non-empty context root!
				</cfif>
                <cfif rc.files.name is 'todos'>
                    - requires /examples/todos/index.cfm/* as a wildcard pattern for Tomcat!
                </cfif>
			</li>
		</cfif>
	</cfoutput>
	<li><a href="examples/index.cfm">Examples as subsystems</a> - reuses some of the examples "as-is".</li>
</ul>
