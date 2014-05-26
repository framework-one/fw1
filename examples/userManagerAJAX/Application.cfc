component extends="org.corfield.framework" {
	
	this.mappings["/userManagerAJAX"] = getDirectoryFromPath(getCurrentTemplatePath());
	this.name = 'fw1-userManagerAJAX';
	
	// FW/1 - configuration:
	variables.framework = {
		home = "user.default"
	};
	
	function setupApplication() 
	{
        setBeanFactory( new framework.ioc( "model" ) );
	}
	
	function setupRequest()
	{
		controller( 'user.checkAjaxRequest' );
	}
    
    function redirect( string action, string preserve = "none", string append = "none",
                       string path = variables.framework.baseURL, string queryString = "" ) {
        if ( append != "all" ) {
            if ( append == "none" ) {
                append = "";
            }
            append = listAppend( append, "isAjaxRequest" );
        }
        super.redirect( argumentCollection = arguments );
    }

}
