component extends=framework.one {
    this.sessionManagement = true;
    variables.framework = {
        trace : true,
        diComponent : "framework.ioclj",
        diLocations : getDirectoryFromPath( CGI.SCRIPT_NAME )
    };
    function setupRequest() {
        // reload Clojure when FW/1 is reloaded:
        if ( isFrameworkReloadRequest() ) {
            getBeanFactory().reload( "all" );
        }
    }
}
