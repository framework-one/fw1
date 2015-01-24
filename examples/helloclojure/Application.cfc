component extends=framework.one {
    variables.framework = {
        trace : true,
        diComponent : "framework.ioclj",
        diLocations : ""
    };
    function setupRequest() {
        // to allow reloading of Clojure code - pass all or a namespace name:
        if ( structKeyExists( URL, "reloadClojure" ) ) {
            getBeanFactory().reload( URL.reloadClojure );
        }
    }
}
