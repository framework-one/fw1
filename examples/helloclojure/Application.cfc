component extends=framework.one {
    variables.framework.trace = true;
    function setupApplication() {
        var clj = { };
        var ns = ["hello.controllers.main",
                  "clojure.walk", "clojure.core"];
        new framework.cfmljure( expandPath( "." ) ).install( ns, clj );
        application.clj = clj;
    }
    function setupRequest() {
        if ( isFrameworkReloadRequest() ) {
            var core = application.clj.clojure.core;
            core.require(
                core.symbol("hello.controllers.main"),
                core.keyword("reload-all")
            );
        }
    }
}
