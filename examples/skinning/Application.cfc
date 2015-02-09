component extends="framework.one" {

	this.sessionManagement = true;
	
	variables.framework = structNew();
	variables.framework.defaultItem = 'index';

	function setupRequest() {
		controller( 'skin' );
	}

	function customizeViewOrLayoutPath( pathInfo, type, fullPath ) {
		// fullPath is: '#pathInfo.base##type#s/#pathInfo.path#.cfm'
		var defaultPath = '#type#s/#pathInfo.path#.cfm';

		if ( fileExists( expandPath( request.subsystembase & '/skins/' & request.context.skin & '/' & defaultPath ) ) ) {
			return request.subsystembase & 'skins/' & request.context.skin & '/' & defaultPath;
		} else {
			return request.subsystembase & 'skins/default/' & defaultPath;
		}
	}

}
