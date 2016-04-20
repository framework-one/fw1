component extends=framework.one {
    function before( rc ) {
        rc["pc"] = getPageContext();
        rc["ioc"] = getBeanFactory();
    }
    function setupRequest() {
        // reload Clojure when FW/1 is reloaded:
        if ( isFrameworkReloadRequest() ) {
            getBeanFactory().reload( "all" );
        }
    }
}
