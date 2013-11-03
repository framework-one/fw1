/*
	Copyright (c) 2010-2013, Sean Corfield

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
component {

	// CONSTRUCTOR
	
	public any function init( string folders, struct config = { } ) {
		variables.folders = folders;
		variables.config = config;
		variables.beanInfo = { };
		variables.beanCache = { };
        variables.settersInfo = { };
		variables.autoExclude = [ '/WEB-INF', '/Application.cfc',
                                  'framework.cfc', 'ioc.cfc' ];
        variables.listeners = 0;
		setupFrameworkDefaults();
		return this;
	}
	
	// PUBLIC METHODS

    // programmatically register an alias
    public any function addAlias( string aliasName, string beanName ) {
		discoverBeans( variables.folders );
        variables.beanInfo[ aliasName ] = variables.beanInfo[ beanName ];
        return this;
    }

	
	// programmatically register new beans with the factory (add a singleton name/value pair)
	public any function addBean( string beanName, any beanValue ) {
		discoverBeans( variables.folders );
		variables.beanInfo[ beanName ] = { value = beanValue, isSingleton = true };
        return this;
	}
	
	
	// return true if the factory (or a parent factory) knows about the requested bean
	public boolean function containsBean( string beanName ) {
		discoverBeans( variables.folders );
		return structKeyExists( variables.beanInfo, beanName ) ||
				( structKeyExists( variables, 'parent' ) && variables.parent.containsBean( beanName ) );
	}
	
	
	// programmatically register new beans with the factory (add an actual CFC)
	public any function declareBean( string beanName, string dottedPath, boolean isSingleton = true, struct overrides = { } ) {
		discoverBeans( variables.folders );
		var singleDir = '';
		if ( listLen( dottedPath, '.' ) > 1 ) {
			var cfc = listLast( dottedPath, '.' );
			var dottedPart = left( dottedPath, len( dottedPath ) - len( cfc ) - 1 );
			singleDir = singular( listLast( dottedPart, '.' ) );
		}
		var cfcPath = replace( expandPath( '/' & replace( dottedPath, '.', '/', 'all' ) & '.cfc' ), chr(92), '/', 'all' );
		var metadata = { 
			name = beanName, qualifier = singleDir, isSingleton = isSingleton, 
			path = cfcPath, cfc = dottedPath, metadata = cleanMetadata( dottedPath ),
            overrides = overrides
		};
		variables.beanInfo[ beanName ] = metadata;
        return this;
	}
	
	
	// return the requested bean, fully populated
	public any function getBean( string beanName ) {
		discoverBeans( variables.folders );
		if ( structKeyExists( variables.beanInfo, beanName ) ) {
			return resolveBean( beanName );
		} else if ( structKeyExists( variables, 'parent' ) ) {
			return variables.parent.getBean( beanName );
		} else {
			throw 'bean not found: #beanName#';
		}
	}
	
	// convenience API for metaprogramming perhaps?
	public any function getBeanInfo( string beanName = '' ) {
		discoverBeans( variables.folders );
		if ( len( beanName ) ) {
            // ask about a specific bean:
			if ( structKeyExists( variables.beanInfo, beanName ) ) {
				return variables.beanInfo[ beanName ];
			}
            if ( structKeyExists( variables, 'parent' ) ) {
                return parentBeanInfo( beanName );
			}
			throw 'bean not found: #beanName#';
		} else if ( structKeyExists( variables, 'parent' ) ) {
			return {
                beanInfo = variables.beanInfo,
                parent = parentBeanInfoList()
            };
		} else {
			return { beanInfo = variables.beanInfo };
		}
	}


    // return the DI/1 version
    public string function getVersion() {
        return variables.config.version;
    }
	
	
	// return true iff bean is known to be a singleton
	public boolean function isSingleton( string beanName ) {
		discoverBeans( variables.folders );
		if ( structKeyExists( variables.beanInfo, beanName ) ) {
			return variables.beanInfo[ beanName ].isSingleton;
		} else if ( structKeyExists( variables, 'parent' ) ) {
            try {
			    return variables.parent.isSingleton( beanName );
            } catch ( any e ) {
                return false; // parent doesn't know the bean therefore is it not singleton
            }
		} else {
			return false; // we don't know the bean therefore it is not a managed singleton
		}
	}
	
	
	// given a bean (by name, by type or by value), call the named
    // setters with the specified property values
	public any function injectProperties( any bean, struct properties ) {
		if ( isSimpleValue( bean ) ) {
            if ( containsBean( bean ) ) bean = getBean( bean );
            else bean = createObject( 'component', bean );
        }
		for ( var property in properties ) {
			if ( !isNull( properties[ property ] ) ) {
				var args = { };
				args[ property ] = properties[ property ];
				evaluate( 'bean.set#property#( argumentCollection = args )' );
			}
		}
		return bean;
	}
	
	
	// empty the cache and reload all the singleton beans
	// note: this does not reload the parent - if you have parent/child factories you
	// are responsible for dealing with that logic (it's safe to reload a child but
	// if you reload the parent, you must reload *all* child factories to ensure
	// things stay consistent!)
	public any function load() {
		discoverBeans( variables.folders );
		variables.beanCache = { };
		for ( var key in variables.beanInfo ) {
			if ( variables.beanInfo[ key ].isSingleton ) getBean( key );
		}
        return this;
	}


    // add a listener for processing after a (re)load of the factory
    // called with just the factory, should be a plain function
    public any function onLoad( any listener ) {
        var head = { next = variables.listeners, listener = listener };
        variables.listeners = head;
        return this;
    }
	
	
	// set the parent bean factory
	public any function setParent( any parent ) {
		variables.parent = parent;
        return this;
	}
	
	// PRIVATE METHODS
	
	private boolean function beanIsTransient( string singleDir, string dir, string beanName ) {
		return singleDir == 'bean' ||
            structKeyExists( variables.transients, dir ) ||
            ( structKeyExists( variables.config, "singletonPattern" ) &&
              refindNoCase( variables.config.singletonPattern, beanName ) == 0 ) ||
            ( structKeyExists( variables.config, "transientPattern" ) &&
              refindNoCase( variables.config.transientPattern, beanName ) > 0 );
	}


	private any function cachable( string beanName) {
		var newObject = false;
		var info = variables.beanInfo[ beanName ];
		if ( info.isSingleton ) {
			// cache on the qualified bean name:
			var qualifiedName = beanName;
			if ( structKeyExists( info, 'name' ) && structKeyExists( info, 'qualifier' ) ) {
			    qualifiedName = info.name & info.qualifier;
			}
			if ( !structKeyExists( variables.beanCache, qualifiedName ) ) {
			    variables.beanCache[ qualifiedName ] = createObject( 'component', info.cfc );
				newObject = true;
			}
			return { bean = variables.beanCache[ qualifiedName ], newObject = newObject };
		} else {
		    return { bean = createObject( 'component', info.cfc ), newObject = true };
		}
	}

	
	private struct function cleanMetadata( string cfc ) {
		var baseMetadata = getComponentMetadata( cfc );
		var iocMeta = { setters = { }, pruned = false };
		var md = { extends = baseMetadata };
		do {
			md = md.extends;
		    // gather up setters based on metadata:
		    var implicitSetters = false;
			// we have implicit setters if: accessors="true" or persistent="true"
			if ( structKeyExists( md, 'persistent' ) && isBoolean( md.persistent ) ) {
				implicitSetters = md.persistent;
			}
			if ( structKeyExists( md, 'accessors' ) && isBoolean( md.accessors ) ) {
				implicitSetters = implicitSetters || md.accessors;
			}
			if ( structKeyExists( md, 'properties' ) ) {
				// due to a bug in ACF9.0.1, we cannot use var property in md.properties,
				// instead we must use an explicit loop index... ugh!
				var n = arrayLen( md.properties );
				for ( var i = 1; i <= n; ++i ) {
					var property = md.properties[ i ];
					if ( implicitSetters &&
						 ( !structKeyExists( property, 'setter' ) ||
                           isBoolean( property.setter ) && property.setter ) ) {
						iocMeta.setters[ property.name ] = 'implicit';
					}
				}
			}
			// still looking for a constructor?
			if ( !structKeyExists( iocMeta, 'constructor' ) ) {
				if ( structKeyExists( md, 'functions' ) ) {
					// due to a bug in ACF9.0.1, we cannot use var property in md.functions,
					// instead we must use an explicit loop index... ugh!
					var n = arrayLen( md.functions );
					for ( var i = 1; i <= n; ++i ) {
						var func = md.functions[ i ];
						if ( func.name == 'init' ) {
							iocMeta.constructor = { };
							if ( structKeyExists( func, 'parameters' ) ) {
								// due to a bug in ACF9.0.1, we cannot use var arg in func.parameters,
								// instead we must use an explicit loop index... ugh!
								var m = arrayLen( func.parameters );
								for ( var j = 1; j <= m; ++j ) {
									var arg = func.parameters[ j ];
									iocMeta.constructor[ arg.name ] = structKeyExists( arg, 'required' ) ? arg.required : false;
								}
							}
						}
					}
				}
			}
		} while ( structKeyExists( md, 'extends' ) );
		return iocMeta;
	}
	
	
	private string function deduceDottedPath( string path, string truePath, string mapping, boolean rootRelative ) {
		if ( rootRelative ) {
			var remaining = right( path, len( path ) - len( truePath ) );
			// strip leading / if present and strip trailing .cfc:
			if ( left( remaining, 1 ) == '/' ) remaining = right( remaining, len( remaining ) - 1 );
			remaining = left( remaining, len( remaining ) - 4 );
			remaining = replace( remaining, '/', '.', 'all' );
			if ( len( mapping ) ) {
				return mapping & '.' & remaining;
			} else {
				return remaining;
			}
		} else {
			var webroot = replace( expandPath( '/' ), chr(92), '/', 'all' );
			if ( path.startsWith( webroot ) ) {
				var rootRelativePath = right( path, len( path ) - len( webroot ) );
				return replace( left( rootRelativePath, len( rootRelativePath ) - 4 ), '/', '.', 'all' );
			} else {
				throw 'unable to deduce dot-relative paths outside webroot: #path#';
			}
		}
	}
	
	
	private void function discoverBeans( string folders ) {
		if ( structKeyExists( variables, 'discoveryComplete' ) ) return;
		lock name="#application.applicationName#_ioc1_#folders#" type="exclusive" timeout="30" {
			if ( structKeyExists( variables, 'discoveryComplete' ) ) return;
			var folderArray = listToArray( folders );
			variables.pathMapCache = { };
			for ( var f in folderArray ) {
				discoverBeansInFolder( replace( trim( f ), chr(92), '/', 'all' ) );
			}
			variables.discoveryComplete = true;
		}
        onLoadEvent();
	}
	
	
	private void function discoverBeansInFolder( string mapping ) {
		var folder = replace( expandPath( mapping ), chr(92), '/', 'all' );
		var webroot = replace( expandPath( '/' ), chr(92), '/', 'all' );
		if ( mapping.startsWith( webroot ) ) {
			// must be an already expanded path!
			folder = mapping;
		}
		// treat absolute file paths as not (web)root-relative:
		var rootRelative = left( mapping, 1 ) == '/' && folder != mapping;
		while ( left( mapping, 1 ) == '.' || left( mapping, 1 ) == '/' ) {
			if ( len( mapping ) > 1 ) {
				mapping = right( mapping, len( mapping ) - 1 );
			} else {
				mapping = '';
			}
		}
		mapping = replace( mapping, '/', '.', 'all' );
		// find all the CFCs here:
        var cfcs = [ ];
        try {
		    cfcs = directoryList( folder, variables.config.recurse, 'path', '*.cfc' );
        } catch ( any e ) {
            // assume bad path - ignore it, cfcs is empty list
        }
		for ( var cfcOSPath in cfcs ) {
			var cfcPath = replace( cfcOSPath, chr(92), '/', 'all' );
			// watch out for excluded paths:
			var excludePath = false;
			for ( var pattern in variables.config.exclude ) {
				if ( findNoCase( pattern, cfcPath ) ) {
					excludePath = true;
					continue;
				}
			}
			if ( excludePath ) continue;
			var dirPath = getDirectoryFromPath( cfcPath );
			var dir = listLast( dirPath, '/' );
			var singleDir = singular( dir );
			var file = listLast( cfcPath, '/' );
			var beanName = left( file, len( file ) - 4 );
			var dottedPath = deduceDottedPath( cfcPath, folder, mapping, rootRelative );
			var metadata = { 
				name = beanName, qualifier = singleDir, isSingleton = !beanIsTransient( singleDir, dir, beanName ), 
				path = cfcPath, cfc = dottedPath, metadata = cleanMetadata( dottedPath )
			};
			if ( structKeyExists( variables.beanInfo, beanName ) ) {
				structDelete( variables.beanInfo, beanName );
				variables.beanInfo[ beanName & singleDir ] = metadata;
			} else {
				variables.beanInfo[ beanName ] = metadata;
				variables.beanInfo[ beanName & singleDir ] = metadata;
			}
		}
	}
	
	
	private struct function findSetters( any cfc, struct iocMeta ) {
		var liveMeta = { setters = iocMeta.setters };
		if ( !iocMeta.pruned ) {
			// need to prune known setters of transients:
			for ( var known in iocMeta.setters ) {
				if ( !isSingleton( known ) ) {
					structDelete( iocMeta.setters, known );
				}
			}
			iocMeta.pruned = true;
		}
		// gather up explicit setters:
		for ( var member in cfc ) {
			var method = cfc[ member ];
			var n = len( member );
			if ( isCustomFunction( method ) && left( member, 3 ) == 'set' && n > 3 ) {
				var property = right( member, n - 3 );
				if ( !isSingleton( property ) ) {
					// ignore properties that we know to be transients...
					continue;
				}
				liveMeta.setters[ property ] = 'explicit';
			}
		}
		return liveMeta;
	}
	
	
	private any function forceCache( any bean, string beanName) {
		var info = variables.beanInfo[ beanName ];
		if ( info.isSingleton ) {
			// cache on the qualified bean name:
			var qualifiedName = beanName;
			if ( structKeyExists( info, 'name' ) && structKeyExists( info, 'qualifier' ) ) {
			    qualifiedName = info.name & info.qualifier;
			}
		    variables.beanCache[ qualifiedName ] = bean;
		}
	}

	
	private void function logMissingBean( string beanName, string resolvingBeanName = '' ) {
		var sys = createObject( 'java', 'java.lang.System' );
		if ( len( resolvingBeanName ) ) {
			sys.out.println( 'bean not found: #beanName#; while resolving #resolvingBeanName#' );
		} else {
			sys.out.println( 'bean not found: #beanName#' );
		}
	}
	
	
	private void function missingBean( string beanName, string resolvingBeanName = '' ) {
		if ( variables.config.strict ) {
			if ( len( resolvingBeanName ) ) {
				throw 'bean not found: #beanName#; while resolving #resolvingBeanName#';
			} else {
				throw 'bean not found: #beanName#';
			}
		} else {
			logMissingBean( beanName, resolvingBeanName );
		}
	}


    private void function onLoadEvent() {
        var head = variables.listeners;
        while ( isStruct( head ) ) {
            if ( isCustomFunction( head.listener ) ) {
                head.listener( this );
            } else if ( isObject( head.listener ) ) {
                head.listener.onLoad( this );
            } else if ( isSimpleValue( head.listener ) &&
                        containsBean( head.listener ) ) {
                getBean( head.listener ).onLoad( this );
            } else {
                throw "invalid onLoad listener registered: #head.listener.toString()#";
            }
            head = head.next;
        }
    }


    private any function parentBeanInfo( string beanName ) {
        // intended to be adaptable to whatever the parent is:
        if ( structKeyExists( variables.parent, 'getBeanInfo' ) ) {
            // smells like DI/1 or compatible:
		    return variables.parent.getBeanInfo( beanName );
        }
        if ( structKeyExists( variables.parent, 'getBeanDefinition' ) ) {
            // smells like ColdSpring or compatible:
            return variables.parent.getBeanDefinition( beanName );
        }
        // unknown:
        return { };
    }


    private any function parentBeanInfoList() {
        // intended to be adaptable to whatever the parent is:
        if ( structKeyExists( variables.parent, 'getBeanInfo' ) ) {
            // smells like DI/1 or compatible:
            return variables.parent.getBeanInfo();
        }
        if ( structKeyExists( variables.parent, 'getBeanDefinitionList' ) ) {
            // smells like ColdSpring or compatible:
            return variables.parent.getBeanDefinitionList();
        }
        // unknown
        return { };
    }
	
	
	private any function resolveBean( string beanName ) {
		// do enough resolution to create and initialization this bean
		// returns a struct of the bean and a struct of beans and setters still to run
		var partialBean = resolveBeanCreate( beanName, { injection = { } } );
		// now perform all of the injection:
		for ( var name in partialBean.injection ) {
			var injection = partialBean.injection[ name ];
			for ( var property in injection.setters ) {
				var args = { };
                if ( structKeyExists( injection.overrides, property ) ) {
                    args[ property ] = injection.overrides[ property ];
				} else if ( structKeyExists( partialBean.injection, property ) ) {
					args[ property ] = partialBean.injection[ property ].bean;
				} else if ( structKeyExists( variables, 'parent' ) && variables.parent.containsBean( property ) ) {
					args[ property ] = variables.parent.getBean( property );
				} else {
					missingBean( property, beanName );
					continue;
				}
				evaluate( 'injection.bean.set#property#( argumentCollection = args )' );
			}
		}
		return partialBean.bean;
	}
	
	
	private struct function resolveBeanCreate( string beanName, struct accumulator ) {
		var bean = 0;
		if ( structKeyExists( variables.beanInfo, beanName ) ) {
			var info = variables.beanInfo[ beanName ];
			if ( structKeyExists( info, 'cfc' ) ) {
				var metaBean = cachable( beanName );
                var overrides = structKeyExists( info, 'overrides' ) ? info.overrides : { };
				bean = metaBean.bean;
				if ( metaBean.newObject ) {
				    if ( structKeyExists( info.metadata, 'constructor' ) ) {
					    var args = { };
						for ( var arg in info.metadata.constructor ) {
                            var argBean = { };
                            // handle known required arguments
                            if ( info.metadata.constructor[ arg ] ) {
                                var beanMissing = true;
                                if ( structKeyExists( overrides, arg ) ) {
                                    args[ arg ] = overrides[ arg ];
                                    beanMissing = false;
                                } else if ( containsBean( arg ) ) {
                                    argBean = resolveBeanCreate( arg, accumulator );
                                    if ( structKeyExists( argBean, 'bean' ) ) {
                                        args[ arg ] = argBean.bean;
                                        beanMissing = false;
                                    }
                                }
                                if ( beanMissing ) {
								    throw 'bean not found: #arg#; while resolving constructor arguments for #beanName#';
                                }
                            } else {
                                if ( structKeyExists( overrides, arg ) ) {
                                    args[ arg ] = overrides[ arg ];
                                } else if ( containsBean( arg ) ) {
                                    // optional but present
							        argBean = resolveBeanCreate( arg, accumulator );
							        if ( structKeyExists( argBean, 'bean' ) ) {
							            args[ arg ] = argBean.bean;
							        }
                                } else {
                                    // optional but not present
                                }
                            }
						}
						var __ioc_newBean = evaluate( 'bean.init( argumentCollection = args )' );
						// if the constructor returns anything, it becomes the bean
						// this allows for smart constructors that return things other
						// than the CFC being created, such as implicit factory beans
						// and automatic singletons etc (rare practices in CFML but...)
						if ( isDefined( '__ioc_newBean' ) ) {
						    bean = __ioc_newBean;
							forceCache( bean, beanName );
						}
					}
				}
                if ( !structKeyExists( accumulator.injection, beanName ) ) {
                    if ( !structKeyExists( variables.settersInfo, beanName ) ) {
                        variables.settersInfo[ beanName ] = findSetters( bean, info.metadata );
                    }
				    var setterMeta = {
                        setters = variables.settersInfo[ beanName ].setters,
                        bean = bean,
                        overrides = overrides
                    };
				    accumulator.injection[ beanName ] = setterMeta; 
				    for ( var property in setterMeta.setters ) {
                        if ( structKeyExists( overrides, property ) ) {
                            // skip resolution because we'll inject override
                        } else {
					        resolveBeanCreate( property, accumulator );
                        }
				    }
                }
				accumulator.bean = bean;
			} else if ( structKeyExists( info, 'value' ) ) {
				accumulator.bean = info.value;
				accumulator.injection[ beanName ] = { bean = info.value, setters = { } }; 
			} else {
				throw 'internal error: invalid metadata for #beanName#';
			}
		} else if ( structKeyExists( variables, 'parent' ) && variables.parent.containsBean( beanName ) ) {
			bean = variables.parent.getBean( beanName );
			accumulator.injection[ beanName ] = { bean = bean, setters = { } };
			accumulator.bean = bean;
		} else {
			missingBean( beanName );
		}
		return accumulator;
	}
	
	
	private void function setupFrameworkDefaults() {
		param name = "variables.config.recurse"		default = true;
		param name = "variables.config.strict"		default = false;
		
		if ( !structKeyExists( variables.config, 'exclude' ) ) {
			variables.config.exclude = [ ];
		}
		for ( var elem in variables.autoExclude ) {
			arrayAppend( variables.config.exclude, replace( elem, chr(92), '/', 'all' ) );
		}
		
		// install bean factory constant:
		variables.beanInfo.beanFactory = { value = this, isSingleton = true };
		if ( structKeyExists( variables.config, 'constants' ) ) {
			for ( var beanName in variables.config.constants ) {
				variables.beanInfo[ beanName ] = { value = variables.config.constants[ beanName ], isSingleton = true };
			}
		}
		
		variables.transients = { };
		if ( structKeyExists( variables.config, 'transients' ) ) {
			for ( var transientFolder in variables.config.transients ) {
				variables.transients[ transientFolder ] = true;
			}
		}

        if ( structKeyExists( variables.config, 'singletonPattern' ) &&
             structKeyExists( variables.config, 'transientPattern' ) ) {
            throw 'singletonPattern and transientPattern are mutually exclusive';
        }
				
		variables.config.version = '0.5.0';
	}
	
	
	private string function singular( string plural ) {
		if ( structKeyExists( variables.config, 'singulars' ) && 
				structKeyExists( variables.config.singulars, plural ) ) {
			return variables.config.singulars[ plural ];
		}
		var single = plural;
		var n = len( plural );
		var last = right( plural, 1 );
		if ( last == 's' ) {
			single = left( plural, n - 1 );
		}
		return single;
	}
	
}
