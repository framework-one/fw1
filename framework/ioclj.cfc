component extends=framework.ioc {
    variables._fw1_version = "3.1-beta1";
    variables._ioclj_version = "1.0_snapshot";
/*
    Copyright (c) 2015, Sean Corfield

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

    // CONSTRUCTOR

    public any function init( string folders, struct config = { } ) {
        // find the first folder that includes project.clj - that's our project
        variables.project = findProjectFile( folders );
        // initialize DI/1 parent
        super.init( folders, config );
        discoverClojureFiles();
        // list of namespaces to expose:
        var ns = [ ];
        for ( var beanName in variables.cljBeans ) {
            arrayAppend( ns, replace( variables.cljBeans[ beanName ].ns, "-", "_", "all" ) );
        }
        // and create a cfmljure instance
        var timeout = structKeyExists( config, "timeout" ) ? config.timeout : 300;
        var lein = structKeyExists( config, "lein" ) ? config.lein : "lein";
        var cfmljure = new framework.cfmljure( variables.project, timeout, lein );
        var app = { };
        cfmljure.install( ns, app );
        variables.clojureApp = app;
        variables.cfmljure = cfmljure;
        return this;
    }

    // PUBLIC METHODS

    // return true if the factory (or a parent factory) knows about the requested bean
    public boolean function containsBean( string beanName ) {
        return structKeyExists( variables.cljBeans, beanName ) || super.containsBean( beanName );
    }

    // return the requested bean, fully populated
    public any function getBean( string beanName ) {
        if ( structKeyExists( variables.cljBeans, beanName ) ) {
            var info = variables.cljBeans[ beanName ];
            // navigate to actual namespace "object":
            var ns = variables.clojureApp;
            for ( var x in info.nsx ) {
                ns = ns[ x ];
            }
            if ( info.type == "controller" ) {
                // need a wrapper - try to find FW/1 instance via bean factory:
                var fw = super.containsBean( "fw" ) ? super.getBean( "fw" ) :
                    ( super.containsBean( "fw1" ) ? super.getBean( "fw1" ) :
                        ( super.containsBean( "framework" ) ? super.getBean( "framework" ) :
                            "" ) );
                var controller = new framework.cljcontroller(
                    fw, variables.cfmljure, ns
                );
                return controller;
            } else {
                // expose as a regular bean
                return ns;
            }
        } else {
            return super.getBean( beanName );
        }
    }

    // reload-all a given namespace or reload all
    public void function reload( string ns ) {
        var core = variables.cfmljure.clojure.core;
        if ( ns == "all" ) {
            for ( var beanName in variables.cljBeans ) {
                var info = variables.cljBeans[ beanName ];
                core.require( core.symbol( info.ns ), core.keyword( "reload" ) );
            }
        } else {
            core.require( core.symbol( ns ), core.keyword( "reload-all" ) );
        }
    }

    // PRIVATE HELPERS

    private void function discoverClojureFiles() {
        var cljs = [ ];
        var src = variables.project & "/src";
        var n = len( src ) + 1; // allow for trailing /
        try {
            cljs = directoryList( src, true, "path", "*.clj" );
        } catch ( any e ) {
            // assume bad path and ignore it
        }
        variables.cljBeans = { };
        for ( var cljOSPath in cljs ) {
            var cljPath = replace( cljOSPath, chr(92), "/", "all" );
            cljPath = right( cljPath, len( cljPath ) - n );
            cljPath = left( cljPath, len( cljPath ) - 4 );
            var ns = replace( replace( cljPath, "/", ".", "all" ), "_", "-", "all" );
            var parts = listToArray( cljPath, "/" );
            var nParts = arrayLen( parts );
            if ( nParts >= 3 ) {
                var lbo = parts[ nParts - 1 ];
                var lbo1 = singular( lbo );
                if ( lbo1 != lbo ) {
                    var beanName = parts[ nParts ] & lbo1;
                    if ( structKeyExists( variables.cljBeans, beanName ) ) {
                        throw "#beanName# is not unique (from #cljPath#)";
                    } else {
                        variables.cljBeans[ beanName ] = { ns : ns, nsx : parts, type : lbo1 };
                    }
                }
            }
        }
    }

    private string function findProjectFile( string folderList ) {
        var folders = listToArray( folderList );
        for ( var folder in folders ) {
            var path = replace( expandPath( trim( folder ) ), chr(92), "/", "all" );
            if ( fileExists( path & "/project.clj" ) ) {
                // found our Clojure project, return it
                return path;
            }
        }
        throw "Unable to find project.clj in any of: #folderList#";
    }

}
