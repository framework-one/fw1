component {
    variables._fw1_version   = "4.0.0";
    variables._ioclj_version = "1.0.1";
    /*
      Copyright (c) 2015-2016, Sean Corfield

      Licensed under the Apache License, Version 2.0 (the "License");
      you may not use this file except in compliance with the License.
      You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

      Unless required by applicable law or agreed to in writing, software
      distributed under the License is distributed on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
      See the License for the specific language governing permissions and
      limitations under the License.
    */

    function init( any fw, any cfmljure, any ns ) {
        variables.fw = fw;
        variables.cfmljure = cfmljure;
        variables.ns = ns;
        return this;
    }

    function onMissingMethod( string missingMethodName, struct missingMethodArguments ) {
        if ( structKeyExists( missingMethodArguments, "rc" ) ) {
            var rc = missingMethodArguments.rc;
            try {
                var rcClj = variables.cfmljure.toClojure( rc );
                var rawResult = callClojure( missingMethodName, rcClj );
                var result = variables.cfmljure.toCFML( rawResult );
                structClear( rc );
                structAppend( rc, result );
                // post-process special keys in rc for abort / redirect etc
                var core = variables.cfmljure.clojure.core;
                if ( structKeyExists( rc, "redirect" ) && isStruct( rc.redirect ) &&
                     structKeyExists( rc.redirect, "action" ) ) {
                    if ( isObject( variables.fw ) ) {
                        variables.fw.redirect(
                            action = rc.redirect["action"],
                            preserve = structKeyExists( rc.redirect, "preserve" ) ? rc.redirect["preserve"] : "none",
                            append = structKeyExists( rc.redirect, "append" ) ? rc.redirect["append"] : "none",
                            queryString = structKeyExists( rc.redirect, "queryString" ) ? rc.redirect["queryString"] : "",
                            statusCode = structKeyExists( rc.redirect, "statusCode" ) ? rc.redirect["statusCode"] : "302"
                        );
                    } else {
                        throw "Unable to redirect() due to lack of injected FW/1";
                    }
                }
                if ( structKeyExists( rc, "render" ) && isStruct( rc.render ) &&
                     structKeyExists( rc.render, "type" ) && structKeyExists( rc.render, "data" ) ) {
                    if ( isObject( variables.fw ) ) {
                        var walk = variables.cfmljure.clojure.walk;
                        var renderer = variables.fw.renderData(
                            core.name( rc.render["type"] ),
                            // since Clojure generated the render data we must be careful to
                            // preserve case but still convert keys to strings...
                            walk.stringify_keys( core.get( core.get( rawResult, core.keyword( "render" ) ), core.keyword( "data" ) ) )
                        );
                        if ( structKeyExists( rc.render, "statusCode" ) ) renderer.statusCode( rc.render["statusCode"] );
                        if ( structKeyExists( rc.render, "statusText" ) ) renderer.statusText( rc.render["statusText"] );
                    } else {
                        throw "Unable to renderData() due to lack of injected FW/1";
                    }
                }
                if ( structKeyExists( rc, "view" ) && isStruct( rc.view ) &&
                     structKeyExists( rc.view, "action" ) ) {
                    if ( isObject( variables.fw ) ) {
                        variables.fw.setView( rc.view["action"] );
                    } else {
                        throw "Unable to setView() due to lack of injected FW/1";
                    }
                }
                if ( structKeyExists( rc, "abort" ) && core.keyword_qmark_( rc.abort ) &&
                     core.name( rc.abort ) == "controller" ) {
                    if ( isObject( variables.fw ) ) {
                        variables.fw.abortController();
                    } else {
                        throw "Unable to abortController() due to lack of injected FW/1";
                    }
                }
            } catch ( java.lang.IllegalStateException e ) {
                if ( e.message.startsWith( "Attempting to call unbound fn" ) ) {
                    // no such controller method - ignore it
                    this[ missingMethodName ] = __dummy;
                } else {
                    throw e;
                }
            }
        }
    }

    function setFramework() { }

    function __dummy() { }

    function callClojure( string qualifiedName, any rcClj ) {
        return evaluate( "variables.ns.#qualifiedName#( rcClj )" );
    }

}
