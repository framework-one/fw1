<cfsilent>
	<cfparam name="rc.message" default="" />
	<cfset local.fullDateString = "dddd, mmmm dd, yyyy" />
	<cfset local.shortDateString = "mmm dd, yyyy" />
	<cfset local.timeString = "h:mm tt" />
	<cfset rc.title = 'LitePost Blog - #rc.entry.getTitle()#' />
</cfsilent>

<!--- entry with comments page --->
<cfoutput>
	
	<!--- output entry --->
	<h1>#rc.entry.getTitle()#</h1>
	<p class="author">Posted by #rc.entry.getPostedBy()#, #dateFormat(rc.entry.getEntryDate(), local.shortDateString)# @ #timeFormat(rc.entry.getEntryDate(), local.timeString)#</p>
	<p>#ParagraphFormat(rc.entry.getBody())#</p
	
	<!-- footer at the bottom of every post -->
	<div class="postfooter">
		<span>
			<a href="?#framework.action#=blog.comments&entryID=#rc.entry.getEntryID()#">
				<img src="../assets/images/comment_icon.gif" title="Comments" alt="Comments" border="0" />
			</a>
			<a href="?#framework.action#=blog.comments&entryID=#rc.entry.getEntryID()#">
				Comments (#rc.entry.getNumComments()#)
			</a>
		</span>
		<span class="right">
			<cfif rc.entry.getCategoryID() neq 0>
				<a href="?#framework.action#=blog.main&categoryID=#rc.entry.getCategoryID()#">
					Filed under #rc.entry.getCategory()#
				</a>
			<cfelse>
				Unfiled
			</cfif>
			<!--- 
			<cfif isAdmin>
				<br />
				<a href="#myself#editEntry&entryID=#entry.getEntryID()#">
					<img src="../assets/images/edit_icon.gif" title="Edit Entry" alt="Edit Entry" border="0" />
				</a>
				<a href="javascript:void(0);" onClick="javascript:deleteEntry(#entry.getEntryID()#)">
					<img src="../assets/images/delete_icon.gif" title="Delete Entry" alt="Delete Entry" border="0" />
				</a>
			</cfif>
			--->
		</span>
	</div>
	
	<!--- output comments --->
	<a name="comments"></a>
	<h2>Comments</h2>
	
	<cfset local.comments = rc.entry.getComments() />
	
	<cfif arrayLen(local.comments) gt 0>
		<cfloop index="local.i" from="1" to="#arrayLen(local.comments)#">
			<cfset local.comment = local.comments[local.i] />
			<div class="comment">
				<p>
					<strong>
						<cfif local.comment.getUrl() is not ""><a href="#local.comment.getUrl()#" target="_blank"></cfif>
						#local.comment.getName()#
						<cfif local.comment.getUrl() is not ""></a></cfif>
					</strong> 
					- <em>#dateFormat(local.comment.getDateCreated(), "mm/dd/yyyy")#</em></p>
				<p>#local.comment.getName()# says ... #ParagraphFormat(local.comment.getComment())#</p>
		 	</div>
			<p><a href="##content"><img src="../assets/images/top_icon.gif" alt="top" /></a> <a href="##content">top</a></p>
		</cfloop>
	<cfelse>
		<p>No comments yet. Be the first to add a comment!</p>
	</cfif>
	
	<cfif len(rc.message)>
		<p><strong>#rc.message#</strong></p>
	</cfif>
	
	<h2>Add A Comment </h2>
	<form id="comment" name="comment" action="?#framework.action#=blog.saveComment" method="post">
		<input type="hidden" name="entryID" value="#rc.entry.getEntryID()#" />
		<label>Your Name<br/>
		<input type="text" name="name" value="#rc.commentBean.getName()#" />
		</label>
		<label>Email (not shared with anyone)<br/>
		<input type="text" name="email" value="#rc.commentBean.getEmail()#" />
		</label>
		<label>URL (linked in your post)<br/>
		<input type="text" name="url" value="#rc.commentBean.getUrl()#" />
		</label>
		<label>Comment<br/>
		<textarea name="comment" class="comment">#rc.commentBean.getComment()#</textarea>
		</label>
		<input type="submit" name="submit" value="Submit" class="adminbutton" />
	</form>
  <p>&nbsp;</p>
	
</cfoutput>
