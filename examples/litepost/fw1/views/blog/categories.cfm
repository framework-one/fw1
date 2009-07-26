<cfoutput>
	
<cfif rc.isAdmin>
	<script type="text/javascript">
		function deleteCategory(categoryID) {
			if(confirm("Are you sure you want to delete this category?")) {
				location.href = "?#framework.action#=blog.deleteCategory&categoryID=" + categoryID;
			}
		}
	</script>
</cfif>
<div>
	<h2>
		Categories
		<cfif rc.isAdmin>
			<a href="?#framework.action#=blog.category">
				<img src="../assets/images/add_icon.gif" border="0" title="Add Category" alt="Add Category" />
			</a>
		</cfif>
	</h2>
</div>

<ul>
	
	<cfif arrayLen(rc.categories) lt 1>
		<li><em>no categories</em></li>
	<cfelse>
	
		<cfloop from="1" to="#ArrayLen(rc.categories)#" index="local.i">
			
			<cfset local.category = rc.categories[local.i] />
			<cfset local.catID = local.category.getCategoryID() />
			
			<li>
				<a href="?#framework.action#=blog.main&categoryID=#local.catID#">#local.category.getCategory()#</a> (#local.category.getNumPosts()#)
				[<a href="?#framework.action#=blog.rss&categoryID=#local.category.getCategoryID()#&categoryName=#local.category.getCategory()#">rss</a>]
				<cfif rc.isAdmin>
					&nbsp;
					<a href="?#framework.action#=blog.category&categoryID=#local.catID#">
						<img src="../assets/images/edit_icon.gif" border="0" title="Edit Category" alt="Edit Category" />
					</a>
					<a href="javascript:void(0);" onClick="javascript:deleteCategory(#local.catID#)">
						<img src="../assets/images/delete_icon.gif" border="0" title="Delete Category" alt="Delete Category" />
					</a>
				</cfif>
			</li>
			
		</cfloop>
		
	</cfif>

</ul>

</cfoutput>