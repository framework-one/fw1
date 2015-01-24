component {
    function onMissingMethod( string missingMethodName, struct missingMethodArguments ) {
        var core = application.clj.clojure.core;
        var walk = application.clj.clojure.walk;
        if ( structKeyExists( missingMethodArguments, "method" ) &&
             missingMethodArguments.method == "item" ) {
            var result = walk.stringify_keys(
                application.clj.hello.controllers.main[missingMethodName](
                    walk.keywordize_keys( core.into( core.hash_map(), missingMethodArguments.rc ) )
                )
            );
            structClear( missingMethodArguments.rc );
            structAppend( missingMethodArguments.rc, result );
        }
    }
}
