<cfsilent>
	<cfparam name="rc.message" default="" />
	
	<cfif rc.entryBean.getEntryID() GT 0>
		<cfset local.label = "Update" />
	<cfelse>
		<cfset local.label = "Add" />
	</cfif>
	<cfset rc.title = 'LitePost Blog - #local.label# Entry' />
</cfsilent>

<cfoutput>

	<h1>#local.label# Entry</h1>
	
	<cfif len(rc.message)>
		<p><strong>#rc.message#</strong></p>
	</cfif>
	
	<form id="editEntry" name="editEntry" action="?#framework.action#=blog.saveEntry" method="post">
		<input type="hidden" name="entryID" value="#rc.entryBean.getEntryID()#" />
		<label>Title<br />
		<input name="title" type="text" value="#rc.entryBean.getTitle()#" />
		</label>
		<label>Category<br />
		<cfset local.currCatID = rc.entryBean.getCategoryID() />
		<select name="categoryID">
			<option value="-1" selected>- Select -</option>
			<option value="0" <cfif local.currCatID EQ 0>selected</cfif>>- None -</option>
			<cfloop from="1" to="#arrayLen(rc.categories)#" index="i">
				<cfset local.category = rc.categories[i] />
				<option value="#local.category.getCategoryID()#"<cfif local.category.getCategoryID() eq rc.entryBean.getCategoryID()> selected</cfif>>#local.category.getCategory()#</option>
			</cfloop>
		</select>
		</label>
		<label>Entry<br />
		<textarea name="body" class="entry" cols="" rows="">#rc.entryBean.getBody()#</textarea>
		</label>
		<input type="submit" name="submit" value="#local.label# Entry" class="adminbutton" />
	</form>
	
</cfoutput>