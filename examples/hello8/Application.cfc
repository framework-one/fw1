component extends="framework.one" {
	
	function setupApplication() {
		// manage model and controllers with DI/1:
		var bf = new framework.ioc( "model, controllers" );
		setBeanFactory( bf );
	}
	
}
