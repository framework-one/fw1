component {
    variables._fw1_version = "3.0_snapshot";
    variables._cfmljure_version = "1.0_snapshot";
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
                              string ns = "", any v = 0, any root = 0 ) {
        if ( project != "" ) {
            variables._clj_root = this;
            variables._clj_ns = "";
            var script = getTempFile( getTempDirectory(), "lein" );
            var nl = server.separator.line;
            var cmd = { };
            if ( server.separator.file == "/" ) {
                // *nix / Mac
                cmd = { cd = "cd", run = "sh", arg = script };
            } else {
                // Windows
                script &= ".bat";
                cmd = { cd = "chdir", run = script, arg = "" };
            }
            fileWrite( script,
                       "#cmd.cd# #project#" & nl &
                       "#lein# classpath" & nl );
            var classpath = "";
            // TODO: not sure if this is ACF-compatible...
            execute name="#cmd.run#" arguments="#cmd.arg#" variable="classpath" timeout="#timeout#";
            // could be multiple lines so clean it up:
            classpath = listLast( classpath, nl );
            classpath = replace( classpath, nl, "" );
            // turn the classpath into a URL list:
            var classpathParts = listToArray( classpath, server.separator.path );
            var urls = [ ];
            for ( var part in classpathParts ) {
                if ( !fileExists( part ) && !directoryExists( part ) ) {
                    try {
                        directoryCreate( part );
                    } catch ( any e ) {
                        // ignore and hope for the best - really!
                    }
                }
                if ( !part.endsWith( ".jar" ) && !part.endsWith( server.separator.file ) ) {
                    part &= server.separator.file;
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
            var out = createObject( "java", "java.lang.System" ).out;
            try {
                var clj6 = appCL.loadClass( "clojure.java.api.Clojure" );
                out.println( "Detected Clojure 1.6 or later" );
                this._clj_var  = clj6.getMethod( "var", __classes( "Object", 2 ) );
                this._clj_read = clj6.getMethod( "read", __classes( "String" ) );
            } catch ( any e ) {
                var clj5 = appCL.loadClass( "clojure.lang.RT" );
                out.println( "Falling back to Clojure 1.5 or earlier" );
                this._clj_var  = clj5.getMethod( "var", __classes( "String", 2 ) );
                this._clj_read = clj5.getMethod( "readString", __classes( "String" ) );
            }
            // promote API:
            this.install = this._install;
            this.read = this._read;
            this.toCFML = this._toCFML;
            this.toClojure = this._toClojure;
            // auto-load clojure.core and clojure.walk for clients
            _install( "clojure.core, clojure.walk", this );
        } else if ( !isSimpleValue( v ) ) {
            variables._clj_root = root;
            variables._clj_ns = ns;
            variables._clj_v = v;
            // allow deref on value:
            this.deref = this._deref;
        } else if ( ns != "" ) {
            variables._clj_root = root;
            variables._clj_ns = ns;
        } else {
            throw "cfmljure requires the path of a Leiningen project.";
        }
        return this;
    }

    public any function _( string name ) {
        var v = __( name );
        return v._deref();
    }

    public any function _deref() {
        return variables._clj_root.clojure.core.deref( variables._clj_v );
    }

    public any function _install( any nsList, struct target ) {
        if ( !isArray( nsList ) ) nsList = listToArray( nsList );
        for ( var ns in nsList ) {
            __install( trim( ns ), target );
        }
    }

    public any function _read( string expr ) {
        var args = [ expr ];
        return variables._clj_root._clj_read.invoke( javaCast( "null", 0 ), args.toArray() );
    }

    public any function _toCFML( any expr ) {
        return this.clojure.walk.stringify_keys( expr );
    }

    public any function _toClojure( any expr ) {
        return this.clojure.walk.keywordize_keys(
            isStruct( expr ) ?
                this.clojure.core.into( this.clojure.core.hash_map(), expr ) : expr
        );
    }

    // helper functions:

    private any function __( string name ) {
        if ( !structKeyExists( variables, name ) ) {
            variables[ name ] = new cfmljure(
                v = _var( variables._clj_ns, name ),
                ns = variables._clj_ns,
                root = variables._clj_root
            );
        }
        return variables[ name ];
    }

    private any function __classes( string name, numeric n = 1, string prefix = "java.lang" ) {
        var result = [ ];
        var type = createObject( "java", prefix & "." & name ).getClass();
        while ( n-- > 0 ) arrayAppend( result, type );
        return result.toArray();
    }

    private any function __install( string ns, struct target ) {
        _require( ns );
        ___install( listToArray( ns, "." ), target );
    }

    private any function ___install( array nsParts, struct target ) {
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
            target[ first ].___install( nsParts, target[ first ] );
        }
    }

    private any function _call() {
        switch ( arrayLen( arguments ) ) {
        case 0:
            return variables._clj_v.invoke();
            break;
        case 1:
            return variables._clj_v.invoke( arguments[1] );
            break;
        case 2:
            return variables._clj_v.invoke( arguments[1], arguments[2] );
            break;
        case 3:
            return variables._clj_v.invoke( arguments[1], arguments[2], arguments[3] );
            break;
        case 4:
            return variables._clj_v.invoke( arguments[1], arguments[2], arguments[3],
                                            arguments[4] );
            break;
        case 5:
            return variables._clj_v.invoke( arguments[1], arguments[2], arguments[3],
                                            arguments[4], arguments[5] );
            break;
        case 6:
            return variables._clj_v.invoke( arguments[1], arguments[2], arguments[3],
                                            arguments[4], arguments[5], arguments[6] );
            break;
        case 7:
            return variables._clj_v.invoke( arguments[1], arguments[2], arguments[3],
                                            arguments[4], arguments[5], arguments[6],
                                            arguments[7] );
            break;
        case 8:
            return variables._clj_v.invoke( arguments[1], arguments[2], arguments[3],
                                            arguments[4], arguments[5], arguments[6],
                                            arguments[7], arguments[8] );
            break;
        case 9:
            return variables._clj_v.invoke( arguments[1], arguments[2], arguments[3],
                                            arguments[4], arguments[5], arguments[6],
                                            arguments[7], arguments[8], arguments[9] );
            break;
        case 10:
            return variables._clj_v.invoke( arguments[1], arguments[2], arguments[3],
                                            arguments[4], arguments[5], arguments[6],
                                            arguments[7], arguments[8], arguments[9],
                                            arguments[10] );
            break;
        case 11:
            return variables._clj_v.invoke( arguments[1], arguments[2], arguments[3],
                                            arguments[4], arguments[5], arguments[6],
                                            arguments[7], arguments[8], arguments[9],
                                            arguments[10], arguments[11] );
            break;
        case 12:
            return variables._clj_v.invoke( arguments[1], arguments[2], arguments[3],
                                            arguments[4], arguments[5], arguments[6],
                                            arguments[7], arguments[8], arguments[9],
                                            arguments[10], arguments[11], arguments[12] );
            break;
		case 13:
			return variables._clj_v.invoke( arguments[1], arguments[2], arguments[3], arguments[4], arguments[5],
											arguments[6], arguments[7], arguments[8], arguments[9], arguments[10],
                                            arguments[11], arguments[12], arguments[13] );
		case 14:
			return variables._clj_v.invoke( arguments[1], arguments[2], arguments[3], arguments[4], arguments[5],
											arguments[6], arguments[7], arguments[8], arguments[9], arguments[10],
                                            arguments[11], arguments[12], arguments[13], arguments[14] );
		case 15:
			return variables._clj_v.invoke( arguments[1], arguments[2], arguments[3], arguments[4], arguments[5],
											arguments[6], arguments[7], arguments[8], arguments[9], arguments[10],
                                            arguments[11], arguments[12], arguments[13], arguments[14], arguments[15] );
        default:
            throw "cfmljure cannot call that method with that many arguments.";
            break;
        }
    }

    private void function _require( string ns ) {
        if ( !structKeyExists( variables, "_clj_require" ) ) {
            variables._clj_require = _var( "clojure.core", "require" );
        }
        variables._clj_require.invoke( this.read( ns ) );
    }

    private any function _var( string ns, string name ) {
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
        var ref = left( missingMethodName, 1 ) == "_";
        if ( ref ) {
            missingMethodName = right( missingMethodName, len( missingMethodName ) - 1 );
        }
        var v = __( missingMethodName );
        if ( ref ) {
            return v._deref();
        } else {
            return v._call( argumentCollection = missingMethodArguments );
        }
    }

}
