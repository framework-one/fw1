/*
	Copyright (c) 2010-2011, Sean Corfield

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
		variables.autoExclude = [ '/WEB-INF', '/Application.cfc' ];
		setupFrameworkDefaults();
		return this;
	}
	
	// PUBLIC METHODS
	
	// programmatically register new beans with the factory
	public void function addBean( string beanName, any beanValue ) {
		variables.beanInfo[ beanName ] = { value = beanValue, isSingleton = true };
	}
	
	
	// return true if the factory (or a parent factory) knows about the requested bean
	public boolean function containsBean( string beanName ) {
		discoverBeans( variables.folders );
		return structKeyExists( variables.beanInfo, beanName ) ||
				( structKeyExists( variables, 'parent' ) && variables.parent.containsBean( beanName ) );
	}
	
	
	// return the requested bean, fully populated
	public any function getBean( string beanName ) {
		discoverBeans( variables.folders );
		if ( structKeyExists( variables.beanInfo, beanName ) ) {
			if ( structKeyExists( variables.beanCache, beanName ) ) {
				return variables.beanCache[ beanName ];
			} else {
				var bean = resolveBean( beanName );
				if ( variables.beanInfo[ beanName ].isSingleton ) {
					variables.beanCache[ beanName ] = bean;
				}
				return bean;
			}
		} else if ( structKeyExists( variables, 'parent' ) ) {
			return variables.parent.getBean( beanName );
		} else {
			throw 'bean not found: #beanName#';
		}
	}
	
	
	// given a bean (by name or by value), call the named setters with the specified property values
	public any function injectProperties( any bean, struct properties ) {
		if ( !isSimpleValue( bean ) ) bean = getBean( bean );
		for ( var property in properties ) {
			var args = { };
			args[ property ] = properties[ property ];
			evaluate( 'bean.set#property#( argumentCollection = args )' );
		}
		return bean;
	}
	
	
	// empty the cache and reload all the singleton beans
	public void function load() {
		discoverBeans( variables.folders );
		variables.beanCache = { };
		for ( var key in variables.beanInfo ) {
			if ( variables.beanInfo[ key ].isSingleton ) getBean( key );
		}
	}
	
	
	// set the parent bean factory
	public void function setParent( any parent ) {
		variables.parent = parent;
	}
	
	// PRIVATE METHODS
	
	private boolean function beanIsTransient( string singleDir, string dir, string beanName ) {
		return singleDir == 'bean' || structKeyExists( variables.transients, dir );
	}
	
	
	private struct function cleanMetadata( string cfc ) {
		var baseMetadata = getComponentMetadata( cfc );
		var iocMeta = { setters = { } };
		var md = { extends = baseMetadata };
		do {
			md = md.extends;
			// gather up setters based on metadata:
			var implicitSetters = false;
			// we have implicit setters if: accessors="true" or persistent="true" (and we don't have accessors="false")
			if ( structKeyExists( md, 'accessors' ) && isBoolean( md.accessors ) ) {
				implicitSetters = md.accessors;
			} else if ( structKeyExists( md, 'persistent' ) && isBoolean( md.persistent ) ) {
				implicitSetters = md.persistent;
			}
			if ( structKeyExists( md, 'properties' ) ) {
				// due to a bug in ACF9.0.1, we cannot use var property in md.properties,
				// instead we must use an explicit loop index... ugh!
				var n = arrayLen( md.properties );
				for ( var i = 1; i <= n; ++i ) {
					var property = md.properties[ i ];
					if ( implicitSetters ||
							structKeyExists( property, 'setter' ) && isBoolean( property.setter ) && property.setter ) {
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
									iocMeta.constructor[ arg.name ] = structKeyExists( arg, 'type' ) ? arg.type : 'any';
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
			var webroot = replace( expandPath( '/' ), '\', '/', 'all' );
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
				discoverBeansInFolder( replace( trim( f ), '\', '/', 'all' ) );
			}
			variables.discoveryComplete = true;
		}
	}
	
	
	private void function discoverBeansInFolder( string mapping ) {
		var folder = replace( expandPath( mapping ), '\', '/', 'all' );
		var webroot = replace( expandPath( '/' ), '\', '/', 'all' );
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
		var cfcs = directoryList( folder, variables.config.recurse, 'path', '*.cfc' );
		for ( var cfcOSPath in cfcs ) {
			var cfcPath = replace( cfcOSPath, '\', '/', 'all' );
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
		// gather up explicit setters:
		for ( var member in cfc ) {
			var method = cfc[ member ];
			var n = len( member );
			if ( isCustomFunction( method ) && left( member, 3 ) == 'set' && n > 3 ) {
				var property = right( member, n - 3 );
				liveMeta.setters[ property ] = 'explicit';
			}
		}
		return liveMeta;
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
	
	
	private any function resolveBean( string beanName ) {
		// do enough resolution to create and initialization this bean
		// returns a struct of the bean and a struct of beans and setters still to run
		var partialBean = resolveBeanCreate( beanName, { injection = { } } );
		// now perform all of the injection:
		for ( var name in partialBean.injection ) {
			var injection = partialBean.injection[ name ];
			for ( var property in injection.setters ) {
				var args = { };
				if ( structKeyExists( partialBean.injection, property ) ) {
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
				// use createObject so we have control over initialization:
				bean = createObject( 'component', info.cfc );
				if ( structKeyExists( info.metadata, 'constructor' ) ) {
					var args = { };
					for ( var arg in info.metadata.constructor ) {
						var argBean = resolveBeanCreate( arg, accumulator );
						// this throws a non-intuitive exception unless we step in...
						if ( !structKeyExists( argBean, 'bean' ) ) {
							throw 'bean not found: #arg#; while resolving constructor arguments for #beanName#';
						}
						args[ arg ] = argBean.bean;
					}
					var __ioc_newBean = evaluate( 'bean.init( argumentCollection = args )' );
					// if the constructor returns anything, it becomes the bean
					// this allows for smart constructors that return things other
					// than the CFC being created, such as implicit factory beans
					// and automatic singletons etc (rare practices in CFML but...)
					if ( isDefined( '__ioc_newBean' ) ) bean = __ioc_newBean;
				}
				var setterMeta = findSetters( bean, info.metadata );
				setterMeta.bean = bean;
				accumulator.injection[ beanName ] = setterMeta; 
				for ( var property in setterMeta.setters ) {
					resolveBeanCreate( property, accumulator );
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
			arrayAppend( variables.config.exclude, replace( elem, '\', '/', 'all' ) );
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
		
		variables.config.version = '0.1.2';
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