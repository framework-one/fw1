component {

	// constructor - access to FW/1 API:
	function init(fw) {
		variables.fw = fw;
	}

	// called before any actions:
	function before(rc) {
		
		rc.isAdmin = variables.securityService.isAuthenticated();
		
		rc.bookmarks = variables.bookmarkService.getBookmarks();
		rc.categories = variables.categoryService.getCategoriesWithCounts();
		
	}
	
	// blog actions:
	
	// bookmark - add/edit bookmark:
	function bookmark(rc) {
		
		var id = 0;
		
		if ( structKeyExists( rc, 'bookmarkBean') ) {
			return;
		}
		if ( structKeyExists( rc, 'bookmarkID' ) ) {
			id = val( rc.bookmarkID );
		}
		if ( id == 0 ) {
			rc.bookmarkBean = variables.bookmarkService.getNewBookmark();
		} else {
			rc.bookmarkBean = variables.bookmarkService.getBookmarkById( id );
		}
		
	}
	
	// category - add/edit category:
	function category(rc) {
		
		var id = 0;
		
		if ( structKeyExists( rc, 'categoryBean') ) {
			return;
		}
		if ( structKeyExists( rc, 'categoryID' ) ) {
			id = val( rc.categoryID );
		}
		if ( id == 0 ) {
			rc.categoryBean = variables.categoryService.getNewCategory();
		} else {
			rc.categoryBean = variables.categoryService.getCategoryById( id );
		}
		
	}
	
	// comments - show entry with comments:
	function comments(rc) {
		
		var id = 0;
		
		if ( structKeyExists( rc, 'entryID' ) ) {
			id = val( rc.entryID );
		}
		rc.entry = variables.entryService.getEntryById( id );
		if ( structKeyExists( rc, 'commentBean') ) {
			return;
		}
		rc.commentBean = variables.commentService.getNewComment();
		
	}
	
	// deleteBookmark - delete by ID
	function deleteBookmark(rc) {
		
		var id = 0;
		
		if ( structKeyExists( rc, 'bookmarkID' ) ) {
			id = val( rc.bookmarkID );
		}
		variables.bookmarkService.removeBookmark( id );
		variables.fw.redirect( 'blog.main' );
	}
	
	// deleteCategory - delete by ID
	function deleteCategory(rc) {
		
		var id = 0;
		
		if ( structKeyExists( rc, 'categoryID' ) ) {
			id = val( rc.categoryID );
		}
		variables.categoryService.removeCategory( id );
		variables.fw.redirect( 'blog.main' );
	}
	
	// deleteEntry - delete by ID
	function deleteEntry(rc) {
		
		var id = 0;
		
		if ( structKeyExists( rc, 'entryID' ) ) {
			id = val( rc.entryID );
		}
		// TODO: remove comments for this entry first!
		variables.entryService.removeEntry( id );
		variables.fw.redirect( 'blog.main' );
	}
	
	// doLogin - attempt authentication:
	function doLogin(rc) {
		
		var user = variables.userService.authenticate( rc.username, rc.password );
		
		if ( user.isNull() ) {
			rc.message = 'User not found!';
			variables.fw.redirect( 'blog.login', 'message' );
		} else {
			variables.fw.redirect( 'blog.main' );
		}
		
	}
	
	// entry - add/edit entry:
	function entry(rc) {
		
		var id = 0;
		
		if ( structKeyExists( rc, 'entryBean') ) {
			return;
		}
		if ( structKeyExists( rc, 'entryID' ) ) {
			id = val( rc.entryID );
		}
		if ( id == 0 ) {
			rc.entryBean = variables.entryService.getNewEntry();
		} else {
			rc.entryBean = variables.entryService.getEntryById( id );
		}
		
	}
	
	// logout - end user session:
	function logout(rc) {

		variables.securityService.removeUserSession();
		variables.fw.redirect( 'blog.main' );

	}
	
	// main - home page:
	function main(rc) {
		
		if ( structKeyExists( rc, 'categoryID' ) and val( rc.categoryID ) gt 0 ) {
			rc.entries = variables.entryService.getEntriesByCategoryID(categoryID);
		} else {
			rc.entries = variables.entryService.getEntries();
		}

	}
	
	function rss(rc) {
		
		var args = structCopy( variables.fw.getBlogConfiguration() );
			
		// additional arguments used in RSSService:
		args.eventParameter = variables.fw.getAction();
		args.eventLocation = 'blog.comments';
		args.generator = 'LitePost';
		
		// fixup blogLanguage:
		args.blogLanguage = replace(lcase(args.blogLanguage), "_", "-", "one");
		
		if ( structKeyExists( rc, 'categoryID' ) ) {
			args.categoryId = rc.categoryId;
			args.categoryName = rc.categoryName;
			rc.rss = variables.rssService.getCategoryRSS( argumentCollection=args );
		} else {
			rc.rss = variables.rssService.getBlogRSS( argumentCollection=args );
		}
		
	}
	
	// saveBookmark - create/update bookmark:
	function saveBookmark(rc) {
		
		var bean = variables.bookmarkService.getBookmarkById( rc.bookmarkID );
		
		variables.fw.populate( bean );
		
		if ( bean.validate() ) {

			variables.bookmarkService.saveBookmark( bean );
			variables.fw.redirect( 'blog.main' );
			
		} else {

			rc.message = 'Please complete the bookmark form!';
			rc.bookmarkBean = bean;
			variables.fw.redirect( 'blog.bookmark', 'message,bookmarkBean' );
			
		}
	}

	// saveCategory - create/update category:
	function saveCategory(rc) {
		
		var bean = variables.categoryService.getCategoryById( rc.categoryID );
		
		variables.fw.populate( bean );
		
		if ( bean.validate() ) {

			variables.categoryService.saveCategory( bean );
			variables.fw.redirect( 'blog.main' );
			
		} else {

			rc.message = 'Please complete the category form!';
			rc.categoryBean = bean;
			variables.fw.redirect( 'blog.category', 'message,categoryBean' );
			
		}
	}

	// saveComment - create/update comment:
	function saveComment(rc) {
		
		var bean = variables.commentService.getNewComment();
		
		variables.fw.populate( bean );
		
		if ( bean.validate() ) {

			variables.commentService.saveComment( bean );
			variables.fw.redirect( 'blog.comments', '', 'entryId' );
			
		} else {

			rc.message = 'Please complete the comment form!';
			rc.commentBean = bean;
			variables.fw.redirect( 'blog.comments', 'message,commentBean', 'entryId' );
			
		}
	}

	// saveEntry - create/update entry:
	function saveEntry(rc) {
		
		var bean = variables.entryService.getEntryById( rc.entryID );
		
		variables.fw.populate( bean );
		
		if ( bean.validate() ) {

			variables.entryService.saveEntry( bean );
			variables.fw.redirect( 'blog.main' );
			
		} else {

			rc.message = 'Please complete the entry form!';
			rc.entryBean = bean;
			variables.fw.redirect( 'blog.entry', 'message,entryBean' );
			
		}
	}

	// setters for dependencies:
	function setBookmarkService(bookmarkService) {
		variables.bookmarkService = bookmarkService;
	}
	
	function setCategoryService(categoryService) {
		variables.categoryService = categoryService;
	}
	
	function setCommentService(commentService) {
		variables.commentService = commentService;
	}
	
	function setEntryService(entryService) {
		variables.entryService = entryService;
	}
	
	function setRSSService(rssService) {
		variables.rssService = rssService;
	}
	
	function setSecurityService(securityService) {
		variables.securityService = securityService;
	}
	
	function setUserService(userService) {
		variables.userService = userService;
	}
	
}
