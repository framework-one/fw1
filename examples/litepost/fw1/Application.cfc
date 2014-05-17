component extends="org.corfield.framework" {

	this.name = 'fw1litepost';
	this.sessionmanagement = true;
	
	variables.framework = {
		home = 'blog.main'
	};
	
	function setupApplication() {

		var cs = createObject( 'component', 'coldspring.beans.DefaultXmlBeanFactory' ).init();
		
		cs.loadBeans( '/litepost/config/litepost-services.xml' );
		
		setBeanFactory( cs );

	}
	
	// example of custom method available to framework / controllers:
	function getBlogConfiguration() {
		
		var config = {
			blogName = 'LitePost - FW/1 Edition',
			blogURL = 'http://litepost.local/litepost/fw1',
			blogDescription = 'The FW/1 Edition of LitePost',
			blogLanguage = 'en_US',
			numEntries = 20,
			authorEmail = 'sean@corfield.org',
			webmasterEmail = 'sean@corfield.org'
		};
		
		return config;
		
	}

}
