component extends="org.corfield.framework" {
	
	function setupApplication() {
		// manage entire application with DI/1:
		var bf = new model.ioc( "." );
		setBeanFactory( bf );
	}
	
}