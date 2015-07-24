component extends=framework.one {
    function setupRequest() {
        // reload Clojure when FW/1 is reloaded:
        if ( isFrameworkReloadRequest() ) {
            getBeanFactory().reload( "all" );
        }
    }
}
