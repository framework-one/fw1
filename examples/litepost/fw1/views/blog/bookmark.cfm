<cfsilent>
	<cfparam name="rc.message" default="" />
	
	<cfif rc.bookmarkBean.getBookmarkID() gt 0>
		<cfset local.label="Update" />
	<cfelse>
		<cfset local.label="Create" />
	</cfif>
	<cfset rc.title = 'LitePost Blog - #local.label# Link' />
</cfsilent>

<cfoutput>
	<h1>#local.label# Link</h1>
	
	<cfif len(rc.message)>
		<p><strong>#rc.message#</strong></p>
	</cfif>
	
	<form id="editBookmark" name="editBookmark" method="post" action="?#framework.action#=blog.saveBookmark">
		<input type="hidden" name="bookmarkID" value="#rc.bookmarkBean.getBookmarkID()#" />
		<label>Name<br />
		<input name="name" type="text" value="#rc.bookmarkBean.getName()#" />
		</label>
		<label>Url<br />
		<input name="url" type="text" value="#rc.bookmarkBean.getUrl()#" />
		</label>
		<input type="submit" name="submit" value="#local.label#" class="adminbutton" />
	</form>
</cfoutput>