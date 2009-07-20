<ul>
	<cfoutput query="rc.files">
		<cfif rc.files.type is 'dir' and left(rc.files.name,1) is not '.'>
			<li><a href="examples/#rc.files.name#/">#rc.files.name#</a></li>
		</cfif>
	</cfoutput>
</ul>