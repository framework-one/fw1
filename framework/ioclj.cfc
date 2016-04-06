component extends=framework.ioc {
    variables._fw1_version = "3.5.1";
    variables._ioclj_version = "1.0.0";
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

    public any function init( any folders, struct config = { } ) {
        variables.debug = structKeyExists( config, "debug" ) ? config.debug : false;
        if ( variables.debug ) {
            variables.stdout = createObject( "java", "java.lang.System" ).out;
        }
        // initialize DI/1 parent
        super.init( folders, config );
        variables.cljBeans = { };
        if ( structKeyExists( config, "noClojure" ) && config.noClojure ) return;
        // find the first folder that includes project.clj - that's our project
        variables.project = findProjectFile();
        discoverClojureFiles();
        // list of namespaces to expose:
        var ns = [ ];
        for ( var beanName in variables.cljBeans ) {
            arrayAppend( ns, replace( variables.cljBeans[ beanName ].ns, "-", "_", "all" ) );
        }
        // and create a cfmljure instance
        var timeout = structKeyExists( config, "timeout" ) ? config.timeout : 300;
        var lein = structKeyExists( config, "lein" ) ? config.lein : "lein";
        var useServerScope = structKeyExists( config, "server" ) ? config.server : false;
        var cfmljure = 0;
        if ( useServerScope ) {
            if ( !structKeyExists( server, "__cfmljure" ) ) {
                server.__cfmljure = new framework.cfmljure( variables.project, timeout, lein );
            }
            cfmljure = server.__cfmljure;
        } else {
            cfmljure = new framework.cfmljure( variables.project, timeout, lein );
        }
        if ( cfmljure.isAvailable() ) {
            // Clojure loaded -- install the discovered namespaces
            var app = { };
            cfmljure.install( ns, app );
            variables.clojureApp = app;
        } else {
            // Clojure failed to load -- forget any installed beans
            variables.cljBeans = { };
        }
        variables.cfmljure = cfmljure;
        this.onLoad( function( bf ) {
            // patch DI/1 bean info to include Clojure "beans" -- this allows Clojure
            // to be autowired like any other "value" bean:
            for ( var cljBean in variables.cljBeans ) {
                variables.beanInfo[ cljBean ] = {
                    name : cljBean, value : getBean( cljBean ), isSingleton : true
                };
            }
            // add cfmljure to expose Clojure-related functions:
            bf.addBean( "cfmljure", cfmljure );
        } );
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


    // convenience API for metaprogramming perhaps?
    public any function getBeanInfo( string beanName = '', boolean flatten = false,
                                     string regex = '' ) {
        if ( len( beanName ) ) {
            // ask about a specific bean:
            if ( structKeyExists( variables.cljBeans, beanName ) ) {
                return variables.cljBeans[ beanName ];
            }
            return super.getBeanInfo( beanName, flatten, regex );
        } else {
            var result = super.getBeanInfo( beanName, flatten, regex );
            structAppend( result.beanInfo, variables.cljBeans );
            if ( len( regex ) ) {
                var matched = { };
                for ( var name in result.beanInfo ) {
                    if ( REFind( regex, name ) ) {
                        matched[ name ] = result.beanInfo[ name ];
                    }
                }
                result.beanInfo = matched;
            }
            return result;
        }
    }


    // reload-all a given namespace or reload all
    public void function reload( string ns ) {
        if ( !variables.cfmljure.isAvailable() ) return;
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
            // we also support .cljc files
            var cljcs = directoryList( src, true, "path", "*.cljc" );
            for ( var cljcOSPath in cljcs ) cljs.append( cljcOSPath );
        } catch ( any e ) {
            // assume bad path and ignore it
        }
        for ( var cljOSPath in cljs ) {
            var cljPath = replace( cljOSPath, chr(92), "/", "all" );
            cljPath = right( cljPath, len( cljPath ) - n );
            // allow for extension being either .clj or .cljc
            cljPath = left( cljPath, len( cljPath ) - ( right( cljPath, 1 ) == "c" ? 5 : 4 ) );
            var ns = replace( replace( cljPath, "/", ".", "all" ), "_", "-", "all" );
            // per #366, the pattern allowed is
            // top-level(.optional)*.plural.(prefix.)*name
            // and this will generate prefixNameSingular
            var parts = listToArray( cljPath, "/" );
            var nParts = arrayLen( parts );
            // ignore temp files from editors (starting with .)
            if ( left( parts[ nParts ], 1 ) == "." ) continue;
            if ( nParts >= 3 ) {
                var pluralCandidate = 2;
                do {
                    var lbo = parts[ pluralCandidate ];
                    var lbo1 = singular( lbo );
                    ++pluralCandidate;
                } while ( lbo == lbo1 && pluralCandidate < nParts );
                if ( lbo1 != lbo ) {
                    var beanName = "";
                    while ( pluralCandidate <= nParts ) {
                        beanName &= parts[ pluralCandidate ];
                        ++pluralCandidate;
                    }
                    beanName &= lbo1;
                    if ( structKeyExists( variables.cljBeans, beanName ) ) {
                        throw "#beanName# is not unique (from #cljPath#)";
                    } else {
                        variables.cljBeans[ beanName ] = {
                            ns : ns, nsx : parts, type : lbo1,
                            isSingleton : true // for DI/1 compatibility
                        };
                    }
                } else if ( variables.debug ) {
                    variables.stdout.println( "ioclj: ignoring #cljPath#.clj because it has no plural segment" );
                }
            } else if ( variables.debug ) {
                variables.stdout.println( "ioclj: ignoring #cljPath#.clj because it does not have at least three segments" );
            }
        }
    }

    private string function findProjectFile() {
        for ( var folder in variables.folderArray ) {
            if ( right( folder, 1 ) == "/" ) {
                if ( len( folder ) == 1 ) folder = "";
                else folder = left( folder, len( folder ) - 1 );
            }
            var expandedFolder = expandPath( folder );
            // for ACF11 compatibility, only use expanded path if it exists
            if ( directoryExists( expandedFolder ) ) folder = expandedFolder;
            if ( !directoryExists( folder ) ) continue;
            var path = replace( folder, chr(92), "/", "all" );
            if ( right( path, 1 ) == "/" ) {
                if ( len( path ) == 1 ) path = "";
                else path = left( path, len( path ) - 1 );
            }
            if ( fileExists( path & "/project.clj" ) ) {
                // found our Clojure project, return it
                if ( variables.debug ) variables.stdout.println( "ioclj: using #path#/project.clj for Clojure root" );
                return path;
            }
        }
        throw "Unable to find project.clj in any of: #variables.folderList#";
    }

}
