component extends=framework.ioc {
    variables._fw1_version = "3.0_snapshot";
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
        // TODO: use first folder for now
        variables.project = replace( expandPath( trim( listFirst( folders, ',' ))), chr(92), '/', 'all' );
        // if none contain it, then we're just like DI/1
        // if we find a project, scan src for .clj files and stash those ???
        variables.cljBeans = {
            mainController : {
                ns : "hello.controllers.main",
                nsx : [ "hello", "controllers", "main" ],
                type : "controller"
            }
        };
        // we expose just the controllers to CFML (at the moment)
        var ns = [ ];
        for ( var beanName in variables.cljBeans ) {
            var info = variables.cljBeans[ beanName ];
            if ( info.type == "controller" ) {
                arrayAppend( ns, info.ns );
            }
        }
        // and create a cfmljure instance
        var timeout = structKeyExists( config, "timeout" ) ? config.timeout : 300;
        var lein = structKeyExists( config, "lein" ) ? config.lein : "lein";
        var cfmljure = new framework.cfmljure( variables.project, timeout, lein );
        var app = { };
        cfmljure.install( ns, app );
        variables.clojureApp = app;
        variables.cfmljure = cfmljure;
        // initialize DI/1 parent
        super.init( folders, config );
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
                core.require( core.symbol( info.ns ), core.keyword( "require" ) );
            }
        } else {
            core.require( core.symbol( ns ), core.keyword( "reload-all" ) );
        }
    }

}
