<ul>
	<cfoutput query="rc.files">
		<!--- updated to omit common/home which are part of the subsystems demo --->
		<cfif rc.files.type is 'dir' and left(rc.files.name,1) is not '.' and
				rc.files.name is not 'common' and rc.files.name is not 'home'>
			<li>
				<a href="examples/#rc.files.name#/">#rc.files.name#</a>
				<cfif rc.files.name is 'remote' or rc.files.name is 'litepost'>
					- will not work with a non-empty context root!
				</cfif>
			</li>
		</cfif>
	</cfoutput>
	<li><a href="examples/index.cfm">Examples as subsystems</a> - reuses some of the examples "as-is".</li>
</ul>