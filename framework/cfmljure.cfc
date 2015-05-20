component {
    variables._fw1_version = "3.5.0_snapshot";
    variables._cfmljure_version = "0.2.4_snapshot";
/*
	Copyright (c) 2012-2015, Sean Corfield

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

	// constructor
    public any function init( string project = "", numeric timeout = 300,
                              string lein = "lein", // to allow default to be overridden
                              string ns = "", any root = 0 ) {
        variables.refCache = { };
        if ( project != "" ) {
            variables._clj_root = this;
            variables._clj_ns = "";
            var javaLangSystem = createObject( "java", "java.lang.System" );
            var nl = javaLangSystem.getProperty( "line.separator" );
            var fs = javaLangSystem.getProperty( "file.separator" );
            var nixLike = fs == "/";
            var script = getTempFile( nixLike ? "/tmp" : "/temp", "lein" );
            var cmd = { };
            if ( nixLike ) {
                // *nix / Mac
                cmd = { cd = "cd", run = "/bin/sh", arg = script };
            } else {
                // Windows
                script &= ".bat";
                cmd = { cd = "chdir", run = script, arg = "" };
            }
            fileWrite( script,
                       "#cmd.cd# #project#" & nl &
                       "#lein# with-profile production do clean, compile, classpath" & nl );
            var classpath = "";
            try {
                cfexecute( name="#cmd.run#", arguments="#cmd.arg#", variable="classpath", timeout="#timeout#" );
            } catch ( any e ) {
                if ( structKeyExists( URL, "cfmljure" ) &&
                     URL.cfmljure == "abortOnFailure" ) {
                    writeDump( var = cmd, label = "Unable to cfexecute this" );
                    writeDump( var = e, label = "Full stack trace" );
                    abort;
                }
                throw e;
            }
            // could be multiple lines so clean it up:
            classpath = listLast( classpath, nl );
            classpath = replace( classpath, nl, "" );
            // turn the classpath into a URL list:
            var classpathParts = listToArray( classpath, javaLangSystem.getProperty( "path.separator" ) );
            var urls = [ ];
            for ( var part in classpathParts ) {
                if ( !fileExists( part ) && !directoryExists( part ) ) {
                    try {
                        directoryCreate( part );
                    } catch ( any e ) {
                        // ignore and hope for the best - really!
                    }
                }
                if ( !part.endsWith( ".jar" ) && !part.endsWith( fs ) ) {
                    part &= fs;
                }
                // TODO: shortcut this...
                var file = createObject( "java", "java.io.File" ).init( part );
                arrayAppend( urls, file.toURI().toURL() );
            }
            // extend the classloader - not at all sketchy, honest!
            var threadProxy = createObject( "java", "java.lang.Thread" );
            var appCL = threadProxy.currentThread().getContextClassLoader();
            var urlCLProxy = createObject( "java", "java.net.URLClassLoader" );
            var addURL = urlCLProxy.getClass().getDeclaredMethod( "addURL", __classes( "URL", 1, "java.net" ) );
            addUrl.setAccessible( true ); // hack to make it callable
            for ( var newURL in urls.toArray() ) {
                addURL.invoke( appCL, [ newURL ] );
            }
            variables.out = javaLangSystem.out;
            try {
                var clj6 = appCL.loadClass( "clojure.java.api.Clojure" );
                variables.out.println( "Detected Clojure 1.6 or later" );
                this._clj_var  = clj6.getMethod( "var", __classes( "Object", 2 ) );
                this._clj_read = clj6.getMethod( "read", __classes( "String" ) );
            } catch ( any e ) {
                var clj5 = appCL.loadClass( "clojure.lang.RT" );
                variables.out.println( "Falling back to Clojure 1.5 or earlier" );
                this._clj_var  = clj5.getMethod( "var", __classes( "String", 2 ) );
                this._clj_read = clj5.getMethod( "readString", __classes( "String" ) );
            }
            // promote API:
            this.install = this.__install;
            this.read = this.__read;
            this.toCFML = this.__toCFML;
            this.toClojure = this.__toClojure;
            // auto-load clojure.core and clojure.walk for clients
            __install( "clojure.core, clojure.walk", this );
        } else if ( ns != "" ) {
            variables._clj_root = root;
            variables._clj_ns = ns;
        } else {
            throw "cfmljure requires the path of a Leiningen project.";
        }
        return this;
    }

    public any function _( string name ) {
        return __( name, true );
    }

    public any function __install( any nsList, struct target ) {
        // this assumes a system has either /tmp (Mac/Linux) or /temp (Windows)
        // and that your servlet container server will have write permission!
        var lockFile = directoryExists( "/tmp" ) ? "/tmp/cfmljure.lock" : "/temp/cfmljure.lock";
        while ( fileExists( lockFile ) ) {
            variables.out.println( "Waiting for #lockFile# to be deleted..." );
            sleep( ( 15 * randRange( 1, 15 ) ) * 1000 );
        }
        fileWriteLine( lockFile, "" );
        if ( !isArray( nsList ) ) nsList = listToArray( nsList );
        try {
            for ( var ns in nsList ) {
                __1_install( trim( ns ), target );
            }
        } finally {
            try {
                fileDelete( lockFile );
            } catch ( any e ) {
                variables.out.println( "Unable to delete #lockFile#!!!" );
            }
        }
    }

    public any function __read( string expr ) {
        var args = [ expr ];
        return variables._clj_root._clj_read.invoke( javaCast( "null", 0 ), args.toArray() );
    }

    public any function __toCFML( any expr ) {
        return this.clojure.walk.stringify_keys( expr );
    }

    public any function __toClojure( any expr ) {
        return this.clojure.walk.keywordize_keys(
            isStruct( expr ) ?
                this.clojure.core.into( this.clojure.core.hash_map(), expr ) : expr
        );
    }

    // helper functions:

    public any function __( string name, boolean autoDeref ) {
        if ( !structKeyExists( variables.refCache, name ) ) {
            if ( autoDeref ) {
                variables.refCache[ name ] = variables._clj_root.clojure.core.deref( __var( variables._clj_ns, name ) );
            } else {
                variables.refCache[ name ] = __var( variables._clj_ns, name );
            }
        }
        return variables.refCache[ name ];
    }

    public any function __classes( string name, numeric n = 1, string prefix = "java.lang" ) {
        var result = createObject( "java", "java.util.ArrayList" ).init();
        var type = createObject( "java", prefix & "." & name ).getClass();
        while ( n-- > 0 ) result.add( type );
        var classType = createObject( "java", "java.lang.Class" );
        var arrayType = createObject( "java", "java.lang.reflect.Array" );
        var arrayInstance = arrayType.newInstance( classType.getClass(), result.size() );
        return result.toArray( arrayInstance );
    }

    public any function __1_install( string ns, struct target ) {
        __require( ns );
        __2_install( listToArray( ns, "." ), target );
    }

    public any function __2_install( array nsParts, struct target ) {
        var first = replace( nsParts[ 1 ], "-", "_", "all" );
        var ns = replace( nsParts[ 1 ], "_", "-", "all" );
        var n = arrayLen( nsParts );
        if ( !structKeyExists( target, first ) ) {
            target[ first ] = new cfmljure(
                ns = listAppend( variables._clj_ns, ns, "." ),
                root = variables._clj_root
            );
        }
        if ( n > 1 ) {
            arrayDeleteAt( nsParts, 1 );
            target[ first ].__2_install( nsParts, target[ first ] );
        }
    }

    public any function __call( any v, any argsArray ) {
        switch ( arrayLen( argsArray ) ) {
        case 0:
            return v.invoke();
            break;
        case 1:
            return v.invoke( argsArray[1] );
            break;
        case 2:
            return v.invoke( argsArray[1], argsArray[2] );
            break;
        case 3:
            return v.invoke( argsArray[1], argsArray[2], argsArray[3] );
            break;
        case 4:
            return v.invoke( argsArray[1], argsArray[2], argsArray[3],
                                            argsArray[4] );
            break;
        case 5:
            return v.invoke( argsArray[1], argsArray[2], argsArray[3],
                                            argsArray[4], argsArray[5] );
            break;
        case 6:
            return v.invoke( argsArray[1], argsArray[2], argsArray[3],
                                            argsArray[4], argsArray[5], argsArray[6] );
            break;
        case 7:
            return v.invoke( argsArray[1], argsArray[2], argsArray[3],
                                            argsArray[4], argsArray[5], argsArray[6],
                                            argsArray[7] );
            break;
        case 8:
            return v.invoke( argsArray[1], argsArray[2], argsArray[3],
                                            argsArray[4], argsArray[5], argsArray[6],
                                            argsArray[7], argsArray[8] );
            break;
        case 9:
            return v.invoke( argsArray[1], argsArray[2], argsArray[3],
                                            argsArray[4], argsArray[5], argsArray[6],
                                            argsArray[7], argsArray[8], argsArray[9] );
            break;
        case 10:
            return v.invoke( argsArray[1], argsArray[2], argsArray[3],
                                            argsArray[4], argsArray[5], argsArray[6],
                                            argsArray[7], argsArray[8], argsArray[9],
                                            argsArray[10] );
            break;
        case 11:
            return v.invoke( argsArray[1], argsArray[2], argsArray[3],
                                            argsArray[4], argsArray[5], argsArray[6],
                                            argsArray[7], argsArray[8], argsArray[9],
                                            argsArray[10], argsArray[11] );
            break;
        case 12:
            return v.invoke( argsArray[1], argsArray[2], argsArray[3],
                                            argsArray[4], argsArray[5], argsArray[6],
                                            argsArray[7], argsArray[8], argsArray[9],
                                            argsArray[10], argsArray[11], argsArray[12] );
            break;
		case 13:
			return v.invoke( argsArray[1], argsArray[2], argsArray[3], argsArray[4], argsArray[5],
											argsArray[6], argsArray[7], argsArray[8], argsArray[9], argsArray[10],
                                            argsArray[11], argsArray[12], argsArray[13] );
		case 14:
			return v.invoke( argsArray[1], argsArray[2], argsArray[3], argsArray[4], argsArray[5],
											argsArray[6], argsArray[7], argsArray[8], argsArray[9], argsArray[10],
                                            argsArray[11], argsArray[12], argsArray[13], argsArray[14] );
		case 15:
			return v.invoke( argsArray[1], argsArray[2], argsArray[3], argsArray[4], argsArray[5],
											argsArray[6], argsArray[7], argsArray[8], argsArray[9], argsArray[10],
                                            argsArray[11], argsArray[12], argsArray[13], argsArray[14], argsArray[15] );
        default:
            throw "cfmljure cannot call that method with that many arguments.";
            break;
        }
    }

    public void function __require( string ns ) {
        if ( !structKeyExists( variables, "_clj_require" ) ) {
            variables._clj_require = __var( "clojure.core", "require" );
        }
        variables._clj_require.invoke( this.read( ns ) );
    }

    public any function __var( string ns, string name ) {
        var encodes = [ "_qmark_", "_bang_", "_gt_", "_lt_", "_eq_", "_star_", "_" ];
        var decodes = [ "?",       "!",      ">",    "<",    "=",    "*",      "-" ];
        var n = encodes.len();
        for ( var i = 1; i <= n; ++i ) {
            name = replaceNoCase( name, encodes[i], decodes[i], "all" );
        }
        var args = [ lCase( ns ), lCase( name ) ];
        return variables._clj_root._clj_var.invoke( javaCast( "null", 0 ), args.toArray() );
    }

    public any function onMissingMethod( string missingMethodName, any missingMethodArguments ) {
        if ( left( missingMethodName, 1 ) == "_" ) {
            return __( right( missingMethodName, len( missingMethodName ) - 1 ), true );
        } else {
            return __call( __( missingMethodName, false ), missingMethodArguments );
        }
    }

}
