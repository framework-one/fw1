<cfsilent>
	<cfset local.fullDateString = "dddd, mmmm dd, yyyy" />
	<cfset local.shortDateString = "mmm/dd/yyyy" />
	<cfset local.timeString = "h:mm tt" />
	<cfparam name="rc.message" default="" />
</cfsilent>

<!--- main entries page --->

<cfoutput>
	
	<cfif rc.isAdmin>
	<script type="text/javascript">
		function deleteEntry(entryID) {
			if(confirm("Are you sure you want to delete this entry?")) {
				location.href = "?#framework.action#=blog.deleteEntry&entryID=" + entryID;
			}
		}
	</script>
	
	<div align="right">
		<a href="?#framework.action#=blog.entry">
			<img src="../assets/images/add_icon.gif" title="Add Entry" alt="Add Entry" border="0" />
		</a>
		<a href="?#framework.action#=blog.entry">
			Add Entry
		</a>
	</div>
	</cfif>
	
	<cfif len(rc.message)>
		<p><strong>#rc.message#</strong></p>
	</cfif>
	
	<cfif arrayLen(rc.entries) lt 1>
		<em>no entries</em>
	<cfelse>
	
		<cfloop from="1" to="#ArrayLen(rc.entries)#" index="local.i">
			<cfset local.entry = rc.entries[local.i] />
			
			<h1>#local.entry.getTitle()#</h1>
			<p class="author">Posted by #local.entry.getPostedBy()#, 
				#dateFormat(local.entry.getEntryDate(), local.shortDateString)# @ 
				#timeFormat(local.entry.getEntryDate(), local.timeString)#</p>
			<p>#ParagraphFormat(local.entry.getBody())#</p
			
			<!-- footer at the bottom of every post -->
			<div class="postfooter">
				<span>
					<a href="?#framework.action#=blog.comments&entryID=#local.entry.getEntryID()#">
						<img src="../assets/images/comment_icon.gif" title="Comments" alt="Comments" border="0" />
					</a>
					<a href="?#framework.action#=blog.comments&entryID=#local.entry.getEntryID()#">
						Comments (#local.entry.getNumComments()#)
					</a>
				</span>
				<span class="right">
					<cfif local.entry.getCategoryID() neq 0>
						<a href="?#framework.action#=blog.main&categoryID=#local.entry.getCategoryID()#">
							Filed under #local.entry.getCategory()#
						</a>
					<cfelse>
						Unfiled
					</cfif>
					<cfif rc.isAdmin>
						<br />
						<a href="?#framework.action#=blog.entry&entryID=#local.entry.getEntryID()#">
							<img src="../assets/images/edit_icon.gif" title="Edit Entry" alt="Edit Entry" border="0" />
						</a>
						<a href="javascript:void(0);" onClick="javascript:deleteEntry(#local.entry.getEntryID()#)">
							<img src="../assets/images/delete_icon.gif" title="Delete Entry" alt="Delete Entry" border="0" />
						</a>
					</cfif>
				</span>
			</div>
			
		</cfloop>
	
	</cfif>

</cfoutput>

