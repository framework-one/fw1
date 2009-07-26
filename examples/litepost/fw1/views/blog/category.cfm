<cfsilent>
	<cfparam name="rc.message" default="" />
	
	<cfif rc.categoryBean.getCategoryID() gt 0>
		<cfset local.label="Update" />
	<cfelse>
		<cfset local.label="Create" />
	</cfif>
	<cfset rc.title = 'LitePost Blog - #local.label# Category' />
</cfsilent>

<cfoutput>
	<h1>#local.label# Category</h1>
	
	<cfif len(rc.message)>
		<p><strong>#rc.message#</strong></p>
	</cfif>
	
	<form id="editCategory" name="editCategory" method="post" action="?#framework.action#=blog.saveCategory">
		<input type="hidden" name="categoryID" value="#rc.categoryBean.getCategoryID()#" />
		<label>Category<br />
		<input name="category" type="text" value="#rc.categoryBean.getCategory()#" />
		</label>
		<input type="submit" name="submit" value="#local.label#" class="adminbutton" />
	</form>
</cfoutput>