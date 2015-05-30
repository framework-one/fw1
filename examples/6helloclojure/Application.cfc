component extends=framework.one {
    this.sessionManagement = true;
    variables.framework = {
        trace : true,
        diComponent : "framework.ioclj",
        diLocations : expandPath(".")
    };
    function setupRequest() {
        // to allow reloading of Clojure code - pass all or a namespace name:
        if ( structKeyExists( URL, "reloadClojure" ) ) {
            getBeanFactory().reload( URL.reloadClojure );
        }
    }
}
