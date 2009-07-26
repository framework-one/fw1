<cfoutput>
	
<cfif rc.isAdmin>
	<script type="text/javascript">
		function deleteBookmark(bookmarkID) {
			if(confirm("Are you sure you want to delete this link?")) {
				location.href = "?#framework.action#=blog.deleteBookmark&bookmarkID=" + bookmarkID;
			}
		}
	</script>
</cfif>
<div>
	<h2>
		Links
		<cfif rc.isAdmin>
			<a href="?#framework.action#=blog.bookmark">
				<img src="../assets/images/add_icon.gif" border="0" title="Add Link" alt="Add Link" />
			</a>
		</cfif>
	</h2>
</div>

<ul>
	
	<cfif arrayLen(rc.bookmarks) lt 1>
		<li><em>no links</em></li>
	<cfelse>

		<cfloop from="1" to="#ArrayLen(rc.bookmarks)#" index="local.i">
			
			<cfset local.bookmark = rc.bookmarks[local.i] />
			<cfset local.linkUrl = local.bookmark.getUrl() />
			<cfset local.bkmkID = local.bookmark.getBookmarkID() />
			
			<cfif Left(local.linkUrl,7) NEQ "http://">
				<cfset local.linkUrl = "http://" & local.linkUrl />
			</cfif>
			
			<li>
				<a href="#local.linkUrl#" target="_blank">#local.bookmark.getName()#</a>
				<cfif rc.isAdmin>
					&nbsp;
					<a href="?#framework.action#=blog.bookmark&bookmarkID=#local.bkmkID#">
						<img src="../assets/images/edit_icon.gif" border="0" title="Edit Link" alt="Edit Link" />
					</a>
					<a href="javascript:void(0);" onClick="javascript:deleteBookmark(#local.bkmkID#)">
						<img src="../assets/images/delete_icon.gif" border="0" title="Delete Link" alt="Delete Link" />
					</a>
				</cfif>
			</li>
		</cfloop>
		
	</cfif>

</ul>

</cfoutput>