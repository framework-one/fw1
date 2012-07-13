component {
/*
	Copyright (c) 2009-2011, Sean Corfield, Ryan Cogswell

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

	this.name = hash( getBaseTemplatePath() );
	if ( len( getContextRoot() ) ) {
		variables.cgiScriptName = replace( CGI.SCRIPT_NAME, getContextRoot(), '' );
		variables.cgiPathInfo = replace( CGI.PATH_INFO, getContextRoot(), '' );
	} else {
		variables.cgiScriptName = CGI.SCRIPT_NAME;
		variables.cgiPathInfo = CGI.PATH_INFO;
	}
	request._fw1 = { };
	// do not rely on these, they are meant to be true magic...
	variables.magicApplicationController = '[]';
	variables.magicApplicationAction = '__';
	variables.magicBaseURL = '-[]-';
	
	public void function abortController() {
		request._fw1.abortController = true;
		throw( type="FW1.AbortControllerException", message="abortController() called" );
	}

	public boolean function actionSpecifiesSubsystem( string action ) {

		if ( !usingSubsystems() ) {
			return false;
		}
		return listLen( action, variables.framework.subsystemDelimiter ) > 1 ||
			right( action, 1 ) == variables.framework.subsystemDelimiter;
	}
	
	public void function addRoute( any routes, string target, any methods = [ ], string statusCode = '' ) {
		if ( !isArray( routes ) ) routes = [ routes ];
		if ( !isArray( methods ) ) methods = [ methods ];
		param name="variables.framework.routes" default="#[ ]#"; 
		if ( len( statusCode ) ) target = statusCode & ':' & target;
		for ( var route in routes ) {
			if ( arrayLen( methods ) ) {
				for ( var method in methods ) {
					arrayAppend( variables.framework.routes, { '$#method##route#' = target } );
				}
			} else {
				arrayAppend( variables.framework.routes, { '#route#' = target } );
			}
		}
	}
	
	/*
	 *	buildURL() should be used from views to construct urls when using subsystems or
	 *	in order to provide a simpler transition to using subsystems in the future
	 */
	public string function buildURL( string action = '.', string path = variables.magicBaseURL, any queryString = '' ) {
		if ( action == '.' ) action = getFullyQualifiedAction();
		if ( path == variables.magicBaseURL ) path = getBaseURL();
		var omitIndex = false;
		if ( path == 'useSubsystemConfig' ) {
			var subsystemConfig = getSubsystemConfig( getSubsystem( action ) );
			if ( structKeyExists( subsystemConfig, 'baseURL' ) ) {
				path = subsystemConfig.baseURL;
			} else {
				path = getBaseURL();
			}
		}
		if ( path == 'useCgiScriptName' ) {
			path = CGI.SCRIPT_NAME;
			if ( variables.framework.SESOmitIndex ) {
				path = getDirectoryFromPath( path );
				omitIndex = true;
			}
		} else if ( path == 'useRequestURI' ) {
			path = getPageContext().getRequest().getRequestURI();
			if ( variables.framework.SESOmitIndex ) {
				path = getDirectoryFromPath( path );
				omitIndex = true;
			}
		}
		// if queryString is a struct, massage it into a string
		if ( isStruct( queryString ) && structCount( queryString ) ) {
			var q = '';
			for( var key in queryString ) {
				q &= '#urlEncodedFormat( key )#=#urlEncodedFormat( queryString[ key ] )#&';
			}
			queryString = q;
		}
		else if ( !isSimpleValue( queryString ) ) {
			queryString = '';
		}
		if ( queryString == '' ) {
			// extract query string from action section:
			var q = find( '?', action );
			var a = find( '##', action );
			if ( q > 0 ) {
				queryString = right( action, len( action ) - q );
				if ( q == 1 ) {
					action = '';
				} else {
					action = left( action, q - 1 );
				}
			} else if ( a > 0 ) {
				queryString = right( action, len( action ) - a + 1 );
				if ( a == 1 ) {
					action = '';
				} else {
					action = left( action, a - 1 );
				}
			}
		}
		var cosmeticAction = getFullyQualifiedAction( action );
		var isHomeAction = cosmeticAction == getFullyQualifiedAction( variables.framework.home );
		var isDefaultItem = getItem( cosmeticAction ) == variables.framework.defaultItem;
		
		var initialDelim = '?';
		var varDelim = '&';
		var equalDelim = '=';
		var basePath = '';
		var extraArgs = '';
		var queryPart = '';
		var anchor = '';
		var ses = false;
		if ( find( '?', path ) > 0 ) {
			if ( right( path, 1 ) == '?' || right( path, 1 ) == '&' ) {
				initialDelim = '';
			} else {
				initialDelim = '&';
			}
		} else if ( structKeyExists( request, 'generateSES' ) && request.generateSES ) {
			if ( omitIndex ) {
				initialDelim = '';
			} else {
				initialDelim = '/';
			}
			varDelim = '/';
			equalDelim = '/';
			ses = true;
		}
		var curDelim = varDelim;
		
		if ( usingSubsystems() && getSubsystem( cosmeticAction ) == variables.framework.defaultSubsystem ) {
			cosmeticAction = getSectionAndItem( cosmeticAction );
		}
		
		if ( len( queryString ) ) {
			// extract query part and anchor from query string:
			q = find( '?', queryString );
			if ( q > 0 ) {
				queryPart = right( queryString, len( queryString ) - q );
				if ( q > 1 ) {
					extraArgs = left( queryString, q - 1 );
				}
				a = find( '##', queryPart );
				if ( a > 0 ) {
					anchor = right( queryPart, len( queryPart ) - a );
					if ( a == 1 ) {
						queryPart = '';
					} else {
						queryPart = left( queryPart, a - 1 );
					}
				}
			} else {
				extraArgs = queryString;
				a = find( '##', extraArgs );
				if ( a > 0 ) {
					anchor = right( extraArgs, len( extraArgs ) - a );
					if ( a == 1 ) {
						extraArgs = '';
					} else {
						extraArgs = left( extraArgs, a - 1 );
					}
				}
			}
			if ( ses ) {
				extraArgs = listChangeDelims( extraArgs, '/', '&=' );
			}
		}
		
		if ( ses ) {
			if ( isHomeAction && extraArgs == '' ) {
				basePath = path;
			} else if ( isDefaultItem && extraArgs == '' ) {
				basePath = path & initialDelim & listFirst( cosmeticAction, '.' );
			} else {
				basePath = path & initialDelim & replace( cosmeticAction, '.', '/' );
			}
		} else {
			if ( isHomeAction ) {
				basePath = path;
				curDelim = '?';
			} else if ( isDefaultItem ) {
				basePath = path & initialDelim & variables.framework.action & equalDelim & listFirst( cosmeticAction, '.' );
			} else {
				basePath = path & initialDelim & variables.framework.action & equalDelim & cosmeticAction;
			}
		}
		
		if ( extraArgs != '' ) {
			basePath = basePath & curDelim & extraArgs;
			curDelim = varDelim;
		}
		if ( queryPart != '' ) {
			if ( ses ) {
				basePath = basePath & '?' & queryPart;
			} else {
				basePath = basePath & curDelim & queryPart;
			}
		}
		if ( anchor != '' ) {
			basePath = basePath & '##' & anchor;
		}
		return basePath;
	}

	/*
	 * call this from your Application.cfc methods to queue up additional controller
	 * method calls at the start of the request
	 */
	public void function controller( string action ) {
		var subsystem = getSubsystem( action );
		var section = getSection( action );
		var item = getItem( action );
		var tuple = { };

		if ( structKeyExists( request, 'controllerExecutionStarted' ) ) {
			raiseException( type="FW1.controllerExecutionStarted", message="Controller '#action#' may not be added at this point.",
				detail="The controller execution phase has already started. Controllers may not be added by other controller methods." );
		}

		tuple.controller = getController( section = section, subsystem = subsystem );
		tuple.key = subsystem & variables.framework.subsystemDelimiter & section;
		tuple.item = item;

		if ( structKeyExists( tuple, 'controller' ) && isObject( tuple.controller ) ) {
			if ( !structKeyExists( request, 'controllers' ) ) {
				request.controllers = [ ];
			}
			arrayAppend( request.controllers, tuple );
		}
	}

	/*
	 * can be overridden to customize how views and layouts are found - can be
	 * used to provide skinning / common views / layouts etc
	 */
	public string function customizeViewOrLayoutPath( struct pathInfo, string type, string fullPath ) {
		// fullPath is: '#pathInfo.base##type#s/#pathInfo.path#.cfm'
		return fullPath;
	}

	/*
	 * return the action URL variable name - allows applications to build URLs
	 */
	public string function getAction() {
		return variables.framework.action;
	}
	
	/*
	 * returns the base URL for redirects and links etc
	 * can be overridden if you need to modify this per-request
	 */
	public string function getBaseURL() {
		return variables.framework.baseURL;
	}
	
	/*
	 *	returns whatever the framework has been told is a bean factory
	 *	this will return a subsystem-specific bean factory if one
	 *	exists for the current request's subsystem (or for the specified subsystem
	 *	if passed in)
	 */
	public any function getBeanFactory( string subsystem = '' ) {
		if ( len( subsystem ) > 0 ) {
			if ( hasSubsystemBeanFactory( subsystem ) ) {
				return getSubsystemBeanFactory( subsystem );
			}
			return getDefaultBeanFactory();
		}
		if ( !usingSubsystems() ) {
			return getDefaultBeanFactory();
		}
		if ( structKeyExists( request, 'subsystem' ) && len( request.subsystem ) > 0 ) {
			return getBeanFactory( request.subsystem );
		}
		if ( len( variables.framework.defaultSubsystem ) > 0 ) {
			return getBeanFactory( variables.framework.defaultSubsystem );
		}
		return getDefaultBeanFactory();
	}
	
	/*
	 * return the framework configuration
	 */
	public struct function getConfig()
	{
		// return a copy to make it read only from outside the framework:
		return structCopy( framework );
	}

	/*
	 * returns the bean factory set via setBeanFactory
	 */
	public any function getDefaultBeanFactory() {
		return application[ variables.framework.applicationKey ].factory;
	}

	/*
	 * returns the name of the default subsystem
	 */
	public string function getDefaultSubsystem() {

		if ( !usingSubsystems() ) {
			return '';
		}

		if ( structKeyExists( request, 'subsystem' ) ) {
			return request.subsystem;
		}

		if ( variables.framework.defaultSubsystem == '' ) {
			raiseException( type="FW1.subsystemNotSpecified", message="No subsystem specified and no default configured.",
					detail="When using subsystems, every request should specify a subsystem or variables.framework.defaultSubsystem should be configured." );
		}

		return variables.framework.defaultSubsystem;

	}
	
	
	/*
	 * return an action with all applicable parts (subsystem, section, and item) specified
	 * using defaults from the configuration or request where appropriate
	 */
	public string function getFullyQualifiedAction( string action = request.action ) {
		if ( usingSubsystems() ) {
			return getSubsystem( action ) & variables.framework.subsystemDelimiter & getSectionAndItem( action );
		}

		return getSectionAndItem( action );
	}
	
	
	/*
	 * return the item part of the action
	 */
	public string function getItem( string action = request.action ) {
		return listLast( getSectionAndItem( action ), '.' );
	}
	
	
	/*
	 * return the current route (if any)
	 */
	public string function getRoute() {
		return structKeyExists( request._fw1, 'route' ) ? request._fw1.route : '';
	}
	
	
	/*
	 * return the configured routes
	 */
	public array function getRoutes() {
		return variables.framework.routes;
	}
	
	
	/*
	 * return the section part of the action
	 */
	public string function getSection( string action = request.action ) {
		return listFirst( getSectionAndItem( action ), '.' );
	}
	
	
	/*
	 * return the action without the subsystem
	 */
	public string function getSectionAndItem( string action = request.action ) {
		var sectionAndItem = '';

		if ( usingSubsystems() && actionSpecifiesSubsystem( action ) ) {
			if ( listLen( action, variables.framework.subsystemDelimiter ) > 1 ) {
				sectionAndItem = listLast( action, variables.framework.subsystemDelimiter );
			}
		} else {
			sectionAndItem = action;
		}

		if ( len( sectionAndItem ) == 0 ) {
			sectionAndItem = variables.framework.defaultSection & '.' & variables.framework.defaultItem;
		} else if ( listLen( sectionAndItem, '.' ) == 1 ) {
			if ( left( sectionAndItem, 1 ) == '.' ) {
				if ( structKeyExists( request, 'section' ) ) {
					sectionAndItem = request.section & '.' & listLast( sectionAndItem, '.' );
				} else {
					sectionAndItem = variables.framework.defaultSection & '.' & listLast( sectionAndItem, '.' );
				}
			} else {
				sectionAndItem = listFirst( sectionAndItem, '.' ) & '.' & variables.framework.defaultItem;
			}
		} else {
			sectionAndItem = listFirst( sectionAndItem, '.' ) & '.' & listLast( sectionAndItem, '.' );
		}

		return sectionAndItem;
	}
	
	
	/*
	 * return the default service result key
	 * override this if you want the default service result to be
	 * stored under a different request context key, based on the
	 * requested action, e.g., return getSection( action );
	 */
	public string function getServiceKey( action ) {
		return 'data';
	}
	
	/*
	 * return the subsystem part of the action
	 */
	public string function getSubsystem( string action = request.action ) {
		if ( actionSpecifiesSubsystem( action ) ) {
			return listFirst( action, variables.framework.subsystemDelimiter );
		}
		return getDefaultSubsystem();
	}
	
	/*
	 * return the (optional) configuration for a subsystem
	 */
	public struct function getSubsystemConfig( string subsystem ) {
		if ( structKeyExists( variables.framework.subsystems, subsystem ) ) {
			// return a copy to make it read only from outside the framework:
			return structCopy( variables.framework.subsystems[ subsystem ] );
		}
		return { };
	}

	/*
	 * returns the bean factory set via setSubsystemBeanFactory
	 * same effect as getBeanFactory when not using subsystems
	 */
	public any function getSubsystemBeanFactory( string subsystem ) {

		setupSubsystemWrapper( subsystem );

		return application[ variables.framework.applicationKey ].subsystemFactories[ subsystem ];

	}
	
	/*
	 * returns true iff a call to getBeanFactory() will successfully return a bean factory
	 * previously set via setBeanFactory or setSubsystemBeanFactory
	 */
	public boolean function hasBeanFactory() {

		if ( hasDefaultBeanFactory() ) {
			return true;
		}

		if ( !usingSubsystems() ) {
			return false;
		}

		if ( structKeyExists( request, 'subsystem' ) ) {
			return hasSubsystemBeanFactory(request.subsystem);
		}

		if ( len(variables.framework.defaultSubsystem) > 0 ) {
			return hasSubsystemBeanFactory(variables.framework.defaultSubsystem);
		}

		return false;

	}

	/*
	 * returns true iff the framework has been told about a bean factory via setBeanFactory
	 */
	public boolean function hasDefaultBeanFactory() {
		return structKeyExists( application[ variables.framework.applicationKey ], 'factory' );
	}

	/*
	 * returns true if a subsystem specific bean factory has been set
	 */
	public boolean function hasSubsystemBeanFactory( string subsystem ) {

		ensureNewFrameworkStructsExist();

		return structKeyExists( application[ variables.framework.applicationKey ].subsystemFactories, subsystem );

	}

	/*
	 * layout() may be invoked inside layouts
	 * returns the UI generated by the named layout and body
	 */
	public string function layout( string path, string body ) {
		var layoutPath = parseViewOrLayoutPath( path, 'layout' );
		return internalLayout( layoutPath, body );
	}

	/*
	 * it is better to set up your application configuration in
	 * your setupApplication() method since that is called on a
	 * framework reload
	 * if you do override onApplicationStart(), you must call
	 * super.onApplicationStart() first
	 */
	public any function onApplicationStart() {
		setupFrameworkDefaults();
		setupRequestDefaults();
		setupApplicationWrapper();
	}

	/*
	 * can be overridden, calling super.onError(exception,event) is optional
	 * depending on what error handling behavior you want
	 * note: you need to rename / disable onError() on OpenBD since it does
	 * not seem to be passed exception or event correctly when something fails
	 * in the code...
	 */
	public void function onError( any exception, string event ) {

		try {
			// record details of the exception:
			if ( structKeyExists( request, 'action' ) ) {
				request.failedAction = request.action;
			}
			request.exception = exception;
			request.event = event;
			// reset lifecycle flags:
			structDelete( request, 'controllerExecutionComplete' );
			structDelete( request, 'controllerExecutionStarted' );
			structDelete( request, 'serviceExecutionComplete' );
			// setup the new controller action, based on the error action:
			structDelete( request, 'controllers' );
			
			if ( structKeyExists( variables, 'framework' ) && structKeyExists( variables.framework, 'error' ) ) {
				request.action = variables.framework.error;
			} else {
				// this is an edge case so we don't bother with subsystems etc
				// (because if part of the framework defaults are not present,
				// we'd have to do a lot of conditional logic here!)
				request.action = 'main.error';
			}
			// ensure request.context is available
			if ( !structKeyExists( request, 'context' ) ) {
			    request.context = { };
			}
			
			setupRequestWrapper( false );
			onRequest( '' );
		} catch ( any e ) {
			failure( e, 'onError' );
			failure( exception, event, true );
		}

	}

	/*
	 * this can be overridden if you want to change the behavior when
	 * FW/1 cannot find a matching view
	 */
	public void function onMissingView( struct rc ) {
		// unable to find a matching view - fail with a nice exception
		viewNotFound();
		// if we got here, we would return the string to be rendered
		// but viewNotFound() throws an exception...
	}

	/*
	 * This can be overridden if you want to change the behavior when
	 * FW/1 encounters an error when trying to populate bean properties
	 * using all of the keys in the request context (rather than a
	 * specific list of keys).  By default FW/1 silently ignores these errors.
	 * Available in the arguments are the bean cfc and the property that was
	 * being set when the error occurred as well as the request context structure.
	 * You can also reference the cfcatch variable for details about the error.
	 */
	public void function onPopulateError( any cfc, string property, struct rc ) {
	}

	/*
	 * not intended to be overridden, automatically deleted for CFC requests
	 */
	public any function onRequest( string targetPath ) {

		var out = 0;
		var i = 0;
		var tuple = 0;
		var _data_fw1 = 0;
		var once = { };
		var n = 0;

		request.controllerExecutionStarted = true;
		try {
			if ( structKeyExists( request, 'controllers' ) ) {
				n = arrayLen( request.controllers );
				for ( i = 1; i <= n; i = i + 1 ) {
					tuple = request.controllers[ i ];
					// run before once per controller:
					if ( !structKeyExists( once, tuple.key ) ) {
						once[ tuple.key ] = i;
						doController( tuple.controller, 'before' );
						if ( structKeyExists( request._fw1, "abortController" ) ) abortController();
					}
					doController( tuple.controller, 'start' & tuple.item );
					if ( structKeyExists( request._fw1, "abortController" ) ) abortController();
					doController( tuple.controller, tuple.item );
					if ( structKeyExists( request._fw1, "abortController" ) ) abortController();
				}
			}
			n = arrayLen( request.services );
			for ( i = 1; i <= n; i = i + 1 ) {
				tuple = request.services[i];
				if ( tuple.key == '' ) {
					// throw the result away:
					doService( tuple.service, tuple.item, tuple.args, tuple.enforceExistence );
					if ( structKeyExists( request._fw1, "abortController" ) ) abortController();
				} else {
					_data_fw1 = doService( tuple.service, tuple.item, tuple.args, tuple.enforceExistence );
					if ( structKeyExists( request._fw1, "abortController" ) ) abortController();
					if ( isDefined('_data_fw1') ) {
						request.context[ tuple.key ] = _data_fw1;
					}
				}
			}
			request.serviceExecutionComplete = true;
			if ( structKeyExists( request, 'controllers' ) ) {
				n = arrayLen( request.controllers );
				for ( i = n; i >= 1; i = i - 1 ) {
					tuple = request.controllers[ i ];
					doController( tuple.controller, 'end' & tuple.item );
					if ( structKeyExists( request._fw1, "abortController" ) ) abortController();
					if ( once[ tuple.key ] eq i ) {
						doController( tuple.controller, 'after' );
						if ( structKeyExists( request._fw1, "abortController" ) ) abortController();
					}
				}
			}
		} catch ( FW1.AbortControllerException e ) {
			request.serviceExecutionComplete = true;
		}
		request.controllerExecutionComplete = true;

		buildViewAndLayoutQueue();

		setupView();

		if ( structKeyExists(request, 'view') ) {
			out = internalView( request.view );
		} else {
			out = onMissingView( request.context );
		}
		for ( i = 1; i <= arrayLen(request.layouts); i = i + 1 ) {
			if ( structKeyExists(request, 'layout') && !request.layout ) {
				break;
			}
			out = internalLayout( request.layouts[i], out );
		}
		writeOutput( out );
		setupResponseWrapper();
	}

	/*
	 * it is better to set up your request configuration in
	 * your setupRequest() method
	 * if you do override onRequestStart(), you must call
	 * super.onRequestStart() first
	 */
	public any function onRequestStart( string targetPath ) {

		var pathInfo = variables.cgiPathInfo;

		setupFrameworkDefaults();
		setupRequestDefaults();

		if ( !isFrameworkInitialized() || isFrameworkReloadRequest() ) {
			setupApplicationWrapper();
		}

		if ( !structKeyExists(request, 'context') ) {
			request.context = { };
		}
		// SES URLs by popular request :)
		if ( len( pathInfo ) > len( variables.cgiScriptName ) && left( pathInfo, len( variables.cgiScriptName ) ) == variables.cgiScriptName ) {
			// canonicalize for IIS:
			pathInfo = right( pathInfo, len( pathInfo ) - len( variables.cgiScriptName ) );
		} else if ( len( pathInfo ) > 0 && pathInfo == left( variables.cgiScriptName, len( pathInfo ) ) ) {
			// pathInfo is bogus so ignore it:
			pathInfo = '';
		}
		pathInfo = processRoutes( pathInfo );
		try {
			// we use .split() to handle empty items in pathInfo - we fallback to listToArray() on
			// any system that doesn't support .split() just in case (empty items won't work there!)
			if ( len( pathInfo ) > 1 ) {
				pathInfo = right( pathInfo, len( pathInfo ) - 1 ).split( '/' );
			} else {
				pathInfo = arrayNew( 1 );
			}
		} catch ( any exception ) {
			pathInfo = listToArray( pathInfo, '/' );
		}
		var sesN = arrayLen( pathInfo );
		if ( ( sesN > 0 || variables.framework.generateSES ) && getBaseURL() != 'useRequestURI' ) {
			request.generateSES = true;
		}
		for ( var sesIx = 1; sesIx <= sesN; sesIx = sesIx + 1 ) {
			if ( sesIx == 1 ) {
				request.context[variables.framework.action] = pathInfo[sesIx];
			} else if ( sesIx == 2 ) {
				request.context[variables.framework.action] = pathInfo[sesIx-1] & '.' & pathInfo[sesIx];
			} else if ( sesIx mod 2 == 1 ) {
				request.context[ pathInfo[sesIx] ] = '';
			} else {
				request.context[ pathInfo[sesIx-1] ] = pathInfo[sesIx];
			}
		}
		// certain remote calls do not have URL or form scope:
		if ( isDefined('URL') ) structAppend(request.context,URL);
		if ( isDefined('form') ) structAppend(request.context,form);
		// figure out the request action before restoring flash context:
		if ( !structKeyExists(request.context, variables.framework.action) ) {
			request.context[variables.framework.action] = variables.framework.home;
		} else {
			request.context[variables.framework.action] = getFullyQualifiedAction( request.context[variables.framework.action] );
		}
		if ( variables.framework.noLowerCase ) {
			request.action = validateAction( request.context[variables.framework.action] );
		} else {
			request.action = validateAction( lCase(request.context[variables.framework.action]) );
		}

		restoreFlashContext();
		// ensure flash context cannot override request action:
		request.context[variables.framework.action] = request.action;

		// allow configured extensions and paths to pass through to the requested template.
		// NOTE: for unhandledPaths, we make the list into an escaped regular expression so we match on subdirectories.  
		// Meaning /myexcludepath will match '/myexcludepath' and all subdirectories  
		if ( listFindNoCase( framework.unhandledExtensions, listLast( targetPath, '.' ) ) || 
				REFindNoCase( '^(' & framework.unhandledPathRegex & ')', targetPath ) ) {		
			structDelete(this, 'onRequest');
			structDelete(variables, 'onRequest');
			structDelete(this, 'onError');
			structDelete(variables, 'onError');
		} else {
			setupRequestWrapper( true );
		}
	}

	/*
	 * it is better to set up your session configuration in
	 * your setupSession() method
	 * if you do override onSessionStart(), you must call
	 * super.onSessionStart() first
	 */
	public any function onSessionStart() {
		setupFrameworkDefaults();
		setupRequestDefaults();
		setupSession();
	}
	
	// populate() may be invoked inside controllers
	public any function populate( any cfc, string keys = '', boolean trustKeys = false, boolean trim = false ) {
		if ( keys == '' ) {
			if ( trustKeys ) {
				// assume everything in the request context can be set into the CFC
				for ( var property in request.context ) {
					try {
						var args = { };
						args[ property ] = request.context[ property ];
						if ( trim && isSimpleValue( args[ property ] ) ) args[ property ] = trim( args[ property ] );
						// cfc[ 'set'&property ]( argumentCollection = args ); // ugh! no portable script version of this?!?!
						evaluate( 'cfc.set#property#( argumentCollection = args )' );
					} catch ( any e ) {
						onPopulateError( cfc, property, request.context );
					}
				}
			} else {
				var setters = findImplicitAndExplicitSetters( cfc );
				for ( var property in setters ) {
					if ( structKeyExists( request.context, property ) ) {
						var args = { };
						args[ property ] = request.context[ property ];
						if ( trim && isSimpleValue( args[ property ] ) ) args[ property ] = trim( args[ property ] );
						// cfc[ 'set'&property ]( argumentCollection = args ); // ugh! no portable script version of this?!?!
						evaluate( 'cfc.set#property#( argumentCollection = args )' );
					}
				}
			}
		} else {
			var setters = findImplicitAndExplicitSetters( cfc );
			var keyArray = listToArray( keys );
			for ( var property in keyArray ) {
				var trimProperty = trim( property );
				if ( structKeyExists( setters, trimProperty ) || trustKeys ) {
					if ( structKeyExists( request.context, trimProperty ) ) {
						var args = { };
						args[ trimProperty ] = request.context[ trimProperty ];
						if ( trim && isSimpleValue( args[ trimProperty ] ) ) args[ trimProperty ] = trim( args[ trimProperty ] );
						// cfc[ 'set'&trimproperty ]( argumentCollection = args ); // ugh! no portable script version of this?!?!
						evaluate( 'cfc.set#trimProperty#( argumentCollection = args )' );
					}
				}
			}
		}
		return cfc;
	}
	
	// call from your controller to redirect to a clean URL based on an action, pushing data to flash scope if necessary:
	public void function redirect( string action, string preserve = 'none', string append = 'none', string path = variables.magicBaseURL, string queryString = '' ) {
		if ( path == variables.magicBaseURL ) path = getBaseURL();
		var preserveKey = '';
		if ( preserve != 'none' ) {
			preserveKey = saveFlashContext( preserve );
		}
		var baseQueryString = '';
		if ( append != 'none' ) {
			if ( append == 'all' ) {
				for ( var key in request.context ) {
					if ( isSimpleValue( request.context[ key ] ) ) {
						baseQueryString = listAppend( baseQueryString, key & '=' & urlEncodedFormat( request.context[ key ] ), '&' );
					}
				}
			} else {
				var keys = listToArray( append );
				for ( var key in keys ) {
					if ( structKeyExists( request.context, key ) && isSimpleValue( request.context[ key ] ) ) {
						baseQueryString = listAppend( baseQueryString, key & '=' & urlEncodedFormat( request.context[ key ] ), '&' );
					}
				}
				
			}
		}
		
		if ( baseQueryString != '' ) {
			if ( queryString != '' ) {
				if ( left( queryString, 1 ) == '?' || left( queryString, 1 ) == '##' ) {
					baseQueryString = baseQueryString & queryString;
				} else {
					baseQueryString = baseQueryString & '&' & queryString;
				}
			}
		} else {
			baseQueryString = queryString;
		}
		
		var targetURL = buildURL( action, path, baseQueryString );
		if ( preserveKey != '' && variables.framework.maxNumContextsPreserved > 1 ) {
			if ( find( '?', targetURL ) ) {
				preserveKey = '&#variables.framework.preserveKeyURLKey#=#preserveKey#';
			} else {
				preserveKey = '?#variables.framework.preserveKeyURLKey#=#preserveKey#';
			}
			if ( find( '##', targetURL ) ) {
				targetURL = listFirst( targetURL, '##' ) & preserveKey & '##' & listRest( targetURL, '##' );
			} else {
				targetURL = targetURL & preserveKey;
			}
		}
		setupResponseWrapper();
		location( targetURL, false );
	}
	
	// call this from your controller to queue up additional services
	public void function service( string action, string key, struct args = { }, boolean enforceExistence = true ) {
		var subsystem = getSubsystem( action );
		var section = getSection( action );
		var item = getItem( action );
		var tuple = { };

		if ( structKeyExists( request, "serviceExecutionComplete" ) ) {
			raiseException( type="FW1.serviceExecutionComplete", message="Service '#action#' may not be added at this point.",
				detail="The service execution phase is complete. Services may not be added by end*() or after() controller methods." );
		}

		tuple.service = getService(section=section, subsystem=subsystem);
		tuple.item = item;
		tuple.key = key;
		tuple.args = args;
		tuple.enforceExistence = enforceExistence;

		if ( structKeyExists( tuple, "service" ) && isObject( tuple.service ) ) {
			arrayAppend( request.services, tuple );
		} else if ( enforceExistence ) {
			raiseException( type="FW1.serviceCfcNotFound", message="Service '#action#' does not exist.",
				detail="To have the execution of this service be conditional based upon its existence, pass in a third parameter of 'false'." );
		}
	}
	/*
	 * call this from your setupApplication() method to tell the framework
	 * about your bean factory - only assumption is that it supports:
	 * - containsBean(name) - returns true if factory contains that named bean, else false
	 * - getBean(name) - returns the named bean
	 */
	public void function setBeanFactory( any beanFactory ) {

		application[ variables.framework.applicationKey ].factory = beanFactory;

	}

	/*
	 * use this to override the default layout
	 */
	public void function setLayout( string action ) {
		request.overrideLayoutAction = validateAction( action );
	}
	
	/*
	 * call this from your setupSubsystem() method to tell the framework
	 * about your subsystem-specific bean factory - only assumption is that it supports:
	 * - containsBean(name) - returns true if factory contains that named bean, else false
	 * - getBean(name) - returns the named bean
	 */
	public void function setSubsystemBeanFactory( string subsystem, any factory ) {

		ensureNewFrameworkStructsExist();
		application[ variables.framework.applicationKey ].subsystemFactories[ subsystem ] = factory;

	}

	/*
	 * override this to provide application-specific initialization
	 * if you want the framework to use a bean factory and autowire
	 * controllers and services, call setBeanFactory(factory) in your
	 * setupApplication() method
	 * you do not need to call super.setupApplication()
	 */
	public void function setupApplication() { }

	/*
	 * override this to provide request-specific initialization
	 * you do not need to call super.setupRequest()
	 */
	public void function setupRequest() { }

	/*
	 * override this to provide request-specific finalization
	 * you do not need to call super.setupResponse()
	 */
	public void function setupResponse() { }

	/*
	 * override this to provide session-specific initialization
	 * you do not need to call super.setupSession()
	 */
	public void function setupSession() { }

	/*
	 * override this to provide subsystem-specific initialization
	 * if you want the framework to use a bean factory and autowire
	 * controllers and services, call
	 *   setSubsystemBeanFactory( subsystem, factory )
	 * in your setupSubsystem() method
	 * you do not need to call super.setupSubsystem( subsystem )
	 */
	public void function setupSubsystem( string subsystem ) { }
	
	/*
	 * override this to provide pre-rendering logic, e.g., to
	 * populate the request context with globally required data
	 * you do not need to call super.setupView()
	 */
	public void function setupView() { }
	
	/*
	 * use this to override the default view
	 */
	public void function setView( string action ) {
		request.overrideViewAction = validateAction( action );
	}

	/*
	 * returns true if the application is configured to use subsystems
	 */
	public boolean function usingSubsystems() {
		return variables.framework.usingSubsystems;
	}
	
	/*
	 * view() may be invoked inside views and layouts
	 * returns the UI generated by the named view
	 */
	public string function view( string path, struct args = { } ) {
		var viewPath = parseViewOrLayoutPath( path, "view" );
		return internalView( viewPath, args );
	}
	
	// THE FOLLOWING METHODS SHOULD ALL BE CONSIDERED PRIVATE / UNCALLABLE
	
	private void function autowire( any cfc, any beanFactory ) {
		var setters = findImplicitAndExplicitSetters( cfc );
		for ( var property in setters ) {
			if ( beanFactory.containsBean( property ) ) {
				var args = { };
				args[ property ] = beanFactory.getBean( property );
				// cfc['set'&property](argumentCollection = args) does not work on ACF9
				evaluate( 'cfc.set#property#( argumentCollection = args )' );
			}
		}
	}
	
	private void function buildViewAndLayoutQueue() {
		var siteWideLayoutBase = request.base & getSubsystemDirPrefix( variables.framework.siteWideLayoutSubsystem );
		var testLayout = 0;
		// default behavior:
		var subsystem = request.subsystem;
		var section = request.section;
		var item = request.item;
		var subsystembase = '';
		
		// has view been overridden?
		if ( structKeyExists( request, 'overrideViewAction' ) ) {
			subsystem = getSubsystem( request.overrideViewAction );
			section = getSection( request.overrideViewAction );
			item = getItem( request.overrideViewAction );
			structDelete( request, 'overrideViewAction' );
		}
		subsystembase = request.base & getSubsystemDirPrefix( subsystem );

		// view and layout setup - used to be in setupRequestWrapper():
		request.view = parseViewOrLayoutPath( subsystem & variables.framework.subsystemDelimiter &
													section & '/' & item, 'view' );
		if ( !cachedFileExists( expandPath( request.view ) ) ) {
			request.missingView = request.view;
			// ensures original view not re-invoked for onError() case:
			structDelete( request, 'view' );
		}

		request.layouts = [ ];
		
		// has layout been overridden?
		if ( structKeyExists( request, 'overrideLayoutAction' ) ) {
			subsystem = getSubsystem( request.overrideLayoutAction );
			section = getSection( request.overrideLayoutAction );
			item = getItem( request.overrideLayoutAction );
			structDelete( request, 'overrideLayoutAction' );
		}
		subsystembase = request.base & getSubsystemDirPrefix( subsystem );

		// look for item-specific layout:
		testLayout = parseViewOrLayoutPath( subsystem & variables.framework.subsystemDelimiter &
													section & '/' & item, 'layout' );
		if ( cachedFileExists( expandPath( testLayout ) ) ) {
			arrayAppend( request.layouts, testLayout );
		}
		// look for section-specific layout:
		testLayout = parseViewOrLayoutPath( subsystem & variables.framework.subsystemDelimiter &
													section, 'layout' );
		if ( cachedFileExists( expandPath( testLayout ) ) ) {
			arrayAppend( request.layouts, testLayout );
		}
		// look for subsystem-specific layout (site-wide layout if not using subsystems):
		if ( request.section != 'default' ) {
			testLayout = parseViewOrLayoutPath( subsystem & variables.framework.subsystemDelimiter &
														'default', 'layout' );
			if ( cachedFileExists( expandPath( testLayout ) ) ) {
				arrayAppend( request.layouts, testLayout );
			}
		}
		// look for site-wide layout (only applicable if using subsystems)
		if ( usingSubsystems() && siteWideLayoutBase != subsystembase ) {
			testLayout = parseViewOrLayoutPath( variables.framework.siteWideLayoutSubsystem & variables.framework.subsystemDelimiter &
														'default', 'layout' );
			if ( cachedFileExists( expandPath( testLayout ) ) ) {
				arrayAppend( request.layouts, testLayout );
			}
		}
	}

	private boolean function cachedFileExists( string filePath ) {
		var cache = application[ variables.framework.applicationKey ].cache;
		if ( !variables.framework.cacheFileExists ) {
			return fileExists( filePath );
		}
		param name="cache.fileExists" default="#{ }#";
		if ( !structKeyExists( cache.fileExists, filePath ) ) {
			cache.fileExists[ filePath ] = fileExists( filePath );
		}
		return cache.fileExists[ filePath ];
	}
	
	private string function cfcFilePath( string dottedPath ) {
		if ( dottedPath == '' ) {
			return '/';
		} else {
			return '/' & replace( dottedPath, '.', '/', 'all' ) & '/';
		}
	}
	
	private void function doController( any cfc, string method ) {
		if ( structKeyExists( cfc, method ) || structKeyExists( cfc, 'onMissingMethod' ) ) {
			try {
				evaluate( 'cfc.#method#( rc = request.context )' );
			} catch ( any e ) {
				setCfcMethodFailureInfo( cfc, method );
				rethrow;
			}
		}
	}
	
	private any function doService( any cfc, string method, struct args, boolean enforceExistence ) {
		if ( structKeyExists( cfc, method ) || structKeyExists( cfc, 'onMissingMethod' ) ) {
			try {
				structAppend( args, request.context, false );
				var _result_fw1 = evaluate( 'cfc.#method#( argumentCollection = args )' );
				if ( !isNull( _result_fw1 ) ) {
					return _result_fw1;
				}
			} catch ( any e ) {
				setCfcMethodFailureInfo( cfc, method );
				rethrow;
			}
		} else if ( enforceExistence ) {
			raiseException( type="FW1.serviceMethodNotFound", message="Service method '#method#' does not exist in service '#getMetadata( cfc ).fullname#'.",
				detail="To have the execution of this service method be conditional based upon its existence, pass in a third parameter of 'false'." );
		}
	}
	
	private void function dumpException( any exception ) {
		writeDump( var = exception, label = 'Exception', top = 2 );
	}
	
	private void function ensureNewFrameworkStructsExist() {

		var framework = application[variables.framework.applicationKey];

		if ( !structKeyExists(framework, 'subsystemFactories') ) {
			framework.subsystemFactories = { };
		}

		if ( !structKeyExists(framework, 'subsystems') ) {
			framework.subsystems = { };
		}

	}

	private void function failure( any exception, string event, boolean indirect = false ) {
		var h = indirect ? 3 : 1;
		if ( structKeyExists(exception, 'rootCause') ) {
			exception = exception.rootCause;
		}
		writeOutput( "<h#h#>" & ( indirect ? "Original exception " : "Exception" ) & " in #event#</h#h#>" );
		if ( structKeyExists( request, 'failedAction' ) ) {
			writeOutput( "<p>The action #request.failedAction# failed.</p>" );
		}
		writeOutput( "<h#1+h#>#exception.message#</h#1+h#>" );
		writeOutput( "<p>#exception.detail# (#exception.type#)</p>" );
		dumpException(exception);

	}

	private struct function findImplicitAndExplicitSetters( any cfc ) {
		var baseMetadata = getMetadata( cfc );
		var setters = { };
		// is it already attached to the CFC metadata?
		if ( structKeyExists( baseMetadata, '__fw1_setters' ) )  {
			setters = baseMetadata.__fw1_setters;
		} else {
			var md = { extends = baseMetadata };
			do {
				md = md.extends;
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
						if ( implicitSetters ||
								structKeyExists( property, 'setter' ) && isBoolean( property.setter ) && property.setter ) {
							setters[ property.name ] = 'implicit';
						}
					}
				}
			} while ( structKeyExists( md, 'extends' ) );
			// cache it in the metadata (note: in Railo 3.2 metadata cannot be modified
			// which is why we return the local setters structure - it has to be built
			// on every controller call; fixed in Railo 3.3)
			baseMetadata.__fw1_setters = setters;
		}
		// gather up explicit setters as well
		for ( var member in cfc ) {
			var method = cfc[ member ];
			var n = len( member );
			if ( isCustomFunction( method ) && left( member, 3 ) == 'set' && n > 3 ) {
				var property = right( member, n - 3 );
				setters[ property ] = 'explicit';
			}
		}
		return setters;
	}

	private any function getCachedComponent( string type, string subsystem, string section ) {

		setupSubsystemWrapper( subsystem );
		var cache = application[variables.framework.applicationKey].cache;
		var types = type & 's';
		var cfc = 0;
		var subsystemDir = getSubsystemDirPrefix( subsystem );
		var subsystemDot = replace( subsystemDir, '/', '.', 'all' );
		var subsystemUnderscore = replace( subsystemDir, '/', '_', 'all' );
		var componentKey = subsystemUnderscore & section;
		var beanName = section & type;
		
		if ( !structKeyExists( cache[ types ], componentKey ) ) {
			lock name="fw1_#application.applicationName#_#variables.framework.applicationKey#_#type#_#componentKey#" type="exclusive" timeout="30" {
				if ( !structKeyExists( cache[ types ], componentKey ) ) {
					if ( usingSubsystems() && hasSubsystemBeanFactory( subsystem ) && getSubsystemBeanFactory( subsystem ).containsBean( beanName ) ) {
						cfc = getSubsystemBeanFactory( subsystem ).getBean( beanName );
						if ( type == 'controller' ) injectFramework( cfc );
					} else if ( !usingSubsystems() && hasDefaultBeanFactory() && getDefaultBeanFactory().containsBean( beanName ) ) {
						cfc = getDefaultBeanFactory().getBean( beanName );
						if ( type == 'controller' ) injectFramework( cfc );
					} else {
						if ( type == 'controller' && section == variables.magicApplicationController ) {
							// treat this (Application.cfc) as a controller:
							cfc = this;
						} else if ( cachedFileExists( expandPath( cfcFilePath( request.cfcbase ) & subsystemDir & types & '/' & section & '.cfc' ) ) ) {
							// we call createObject() rather than new so we can control initialization:
							if ( request.cfcbase == '' ) {
								cfc = createObject( 'component', subsystemDot & types & '.' & section );
							} else {
								cfc = createObject( 'component', request.cfcbase & '.' & subsystemDot & types & '.' & section );
							}
							if ( structKeyExists( cfc, 'init' ) ) {
								if ( type == 'controller' ) {
									cfc.init( this );
								} else {
									cfc.init();
								}
							}
						}
						if ( isObject( cfc ) && ( hasDefaultBeanFactory() || hasSubsystemBeanFactory( subsystem ) ) ) {
							autowire( cfc, getBeanFactory( subsystem ) );
						}
					}
					if ( isObject( cfc ) ) {
						cache[ types ][ componentKey ] = cfc;
					}
				}
			}
		}

		if ( structKeyExists( cache[ types ], componentKey ) ) {
			return cache[ types ][ componentKey ];
		}
		// else "return null" effectively
	}
	
	private any function getController( string section, string subsystem = getDefaultSubsystem() ) {
		var _controller_fw1 = getCachedComponent( 'controller', subsystem, section );
		if ( isDefined( '_controller_fw1' ) ) {
			return _controller_fw1;
		}
	}
	
	private string function getNextPreserveKeyAndPurgeOld() {
		var nextPreserveKey = '';
		var oldKeyToPurge = '';
		if ( variables.framework.maxNumContextsPreserved > 1 ) {
			lock scope="session" type="exclusive" timeout="30" {
				param name="session.__fw1NextPreserveKey" default="1";
				nextPreserveKey = session.__fw1NextPreserveKey;
				session.__fw1NextPreserveKey = session.__fw1NextPreserveKey + 1;
			}
			oldKeyToPurge = nextPreserveKey - variables.framework.maxNumContextsPreserved;
		} else {
			lock scope="session" type="exclusive" timeout="30" {
				session.__fw1PreserveKey = '';
				nextPreserveKey = session.__fw1PreserveKey;
			}
			oldKeyToPurge = '';
		}
		var key = getPreserveKeySessionKey( oldKeyToPurge );
		if ( structKeyExists( session, key ) ) {
			structDelete( session, key );
		}
		return nextPreserveKey;
	}
	
	private string function getPreserveKeySessionKey( string preserveKey ) {
		return '__f1' & preserveKey;
	}
	
	private any function getService( string section, string subsystem = getDefaultSubsystem() ) {
		var _service_fw1 = getCachedComponent( 'service', subsystem, section );
		if ( isDefined( '_service_fw1' ) ) {
			return _service_fw1;
		}
	}
	
	private string function getSubsystemDirPrefix( string subsystem ) {

		if ( subsystem eq '' ) {
			return '';
		}

		return subsystem & '/';
	}
	
	private void function injectFramework( any cfc ) {
		var args = { };
		if ( structKeyExists( cfc, 'setFramework' ) ) {
			args.framework = this;
			// allow alternative spellings
			args.fw = this;
			args.fw1 = this;
			evaluate( 'cfc.setFramework( argumentCollection = args )' );
		}
	}
	
	private string function internalLayout( string layoutPath, string body ) {
		var rc = request.context;
		var $ = { };
		// integration point with Mura:
		if ( structKeyExists( rc, '$' ) ) {
			$ = rc.$;
		}
		if ( !structKeyExists( request, 'controllerExecutionComplete' ) ) {
			raiseException( type="FW1.layoutExecutionFromController", message="Invalid to call the layout method at this point.",
				detail="The layout method should not be called prior to the completion of the controller execution phase." );
		}
		var response = '';
		savecontent variable="response" {
			include '#layoutPath#';
		}
		return response;
	}
	
	private string function internalView( string viewPath, struct args = { } ) {
		var rc = request.context;
		var $ = { };
		// integration point with Mura:
		if ( structKeyExists( rc, '$' ) ) {
			$ = rc.$;
		}
		structAppend( local, args );
		if ( !structKeyExists( request, 'serviceExecutionComplete') && arrayLen( request.services ) != 0 ) {
			raiseException( type="FW1.viewExecutionFromController", message="Invalid to call the view method at this point.",
				detail="The view method should not be called prior to the completion of the service execution phase." );
		}
		var response = '';
		savecontent variable="response" {
			include '#viewPath#';
		}
		return response;
	}
	
	private boolean function isFrameworkInitialized() {
		return structKeyExists( application, variables.framework.applicationKey );
	}

	private boolean function isFrameworkReloadRequest() {
		return ( isDefined( 'URL' ) &&
					structKeyExists( URL, variables.framework.reload ) &&
					URL[ variables.framework.reload ] == variables.framework.password ) ||
				variables.framework.reloadApplicationOnEveryRequest;
	}

	private boolean function isSubsystemInitialized( string subsystem ) {

		ensureNewFrameworkStructsExist();

		return structKeyExists( application[ variables.framework.applicationKey ].subsystems, subsystem );

	}

	private string function parseViewOrLayoutPath( string path, string type ) {

		var pathInfo = { };
		var subsystem = getSubsystem( path );

		// allow for :section/action to simplify logic in setupRequestWrapper():
		pathInfo.path = listLast( path, variables.framework.subsystemDelimiter );
		pathInfo.base = request.base;
		pathInfo.subsystem = subsystem;
		if ( usingSubsystems() ) {
			pathInfo.base = pathInfo.base & getSubsystemDirPrefix( subsystem );
		}

		return customizeViewOrLayoutPath( pathInfo, type, '#pathInfo.base##type#s/#pathInfo.path#.cfm' );

	}
	
	private struct function processRouteMatch( string route, string target, string path ) {
		// TODO: could cache preprocessed versions of route / target / etc
		var routeMatch = { matched = false, redirect = false, method = '' };
		// if target has numeric prefix, strip it and set redirect:
		var prefix = listFirst( target, ':' );
		if ( isNumeric( prefix ) ) {
			routeMatch.redirect = true;
			routeMatch.statusCode = prefix;
			target = listRest( target, ':' );
		}
		// special routes begin with $METHOD, * is also a wildcard
		var routeLen = len( route );
		if ( routeLen ) {
			if ( left( route, 1 ) == '$' ) {
				// check HTTP method
				routeMatch.method = listFirst( route, '*/' );
				var methodLen = len( routeMatch.method );
				if ( routeLen == methodLen ) {
					route = '*';
				} else {
					route = right( route, routeLen - methodLen );
				}
			}
			if ( route == '*' ) {
				route = '/';
			} else if ( right( route, 1 ) != '/' ) {
				route &= '/';
			}
		} else {
			route = '/';
		}
		if ( !len( target ) || right( target, 1) != '/' ) target &= '/';
		// walk for :var and replace with ([^/]*) in route and back reference in target:
		var n = 1;
		var placeholders = rematch( ':[^/]+', route );
		for ( var placeholder in placeholders ) {
			route = replace( route, placeholder, '([^/]*)' );
			target = replace( target, placeholder, chr(92) & n );
			++n;
		}
		// add trailing match/back reference:
		route &= '(.*)';
		target &= chr(92) & n;
		// end of preprocessing section
		if ( !len( path ) || right( path, 1) != '/' ) path &= '/';
		var matched = len( routeMatch.method ) ? ( '$' & CGI.REQUEST_METHOD == routeMatch.method ) : true;
		if ( matched && reFind( route, path ) ) {
			routeMatch.matched = true;
			routeMatch.pattern = route;
			routeMatch.target = target;
			routeMatch.path = path;
		}
		return routeMatch;
	}

	private string function processRoutes( string path ) {
		for ( var routePack in variables.framework.routes ) {
			for ( var route in routePack ) {
				if ( route != 'hint' ) {
					var routeMatch = processRouteMatch( route, routePack[ route ], path );
					if ( routeMatch.matched ) {
						path = rereplace( routeMatch.path, routeMatch.pattern, routeMatch.target );
						if ( routeMatch.redirect ) {
							location( path, false, routeMatch.statusCode ); 
						} else {
							request._fw1.route = route;
							return path;
						}
					}
				}
			}
		}
		return path;
	}

	private void function raiseException( string type, string message, string detail ) {
		throw( type = type, message = message, detail = detail );
	}
	
	private void function restoreFlashContext() {
		if ( variables.framework.maxNumContextsPreserved > 1 ) {
			if ( !structKeyExists( URL, variables.framework.preserveKeyURLKey ) ) {
				return;
			}
			var preserveKey = URL[ variables.framework.preserveKeyURLKey ];
			var preserveKeySessionKey = getPreserveKeySessionKey( preserveKey );
		} else {
			var preserveKeySessionKey = getPreserveKeySessionKey( '' );
		}
		try {
			if ( structKeyExists( session, preserveKeySessionKey ) ) {
				structAppend( request.context, session[ preserveKeySessionKey ], false );
				if ( variables.framework.maxNumContextsPreserved == 1 ) {
					/*
						When multiple contexts are preserved, the oldest context is purged
					 	within getNextPreserveKeyAndPurgeOld once the maximum is reached.
					 	This allows for a browser refresh after the redirect to still receive
					 	the same context.
					*/
					structDelete( session, preserveKeySessionKey );
				}
			}
		} catch ( any e ) {
			// session scope not enabled, do nothing
		}
	}
	
	private string function saveFlashContext( string keys ) {
		var curPreserveKey = getNextPreserveKeyAndPurgeOld();
		var preserveKeySessionKey = getPreserveKeySessionKey( curPreserveKey );
		try {
			param name="session.#preserveKeySessionKey#" default="#{ }#";
			if ( keys == 'all' ) {
				structAppend( session[ preserveKeySessionKey ], request.context );
			} else {
				var key = 0;
				var keyNames = listToArray( keys );
				for ( key in keyNames ) {
					if ( structKeyExists( request.context, key ) ) {
						session[ preserveKeySessionKey ][ key ] = request.context[ key ];
					}
				}
			}
		} catch ( any ex ) {
			// session scope not enabled, do nothing
		}
		return curPreserveKey;
	}

	private void function setCfcMethodFailureInfo( any cfc, string method ) {
		var meta = getMetadata( cfc );
		if ( structKeyExists( meta, 'fullname' ) ) {
			request.failedCfcName = meta.fullname;
		} else {
			request.failedCfcName = meta.name;
		}
		request.failedMethod = method;
	}
	
	private void function setupApplicationWrapper() {
		/*
			since this can be called on a reload, we need to lock it to prevent other threads
			trying to reload the app at the same time since we're messing with the main application
			data struct... if the application is already running, we don't blow away the factories
			because we don't want to affect other threads that may be running at this time
		*/
		var frameworkCache = { };
		var framework = { };
		var isReload = true;
		frameworkCache.lastReload = now();
		frameworkCache.fileExists = { };
		frameworkCache.controllers = { };
		frameworkCache.services = { };
		lock name="fw1_#application.applicationName#_#variables.framework.applicationKey#_initialization" type="exclusive" timeout="10" {
			if ( structKeyExists( application, variables.framework.applicationKey ) ) {
				// application is already loaded, just reset the cache and trigger re-initialization of subsystems
				application[variables.framework.applicationKey].cache = frameworkCache;
				application[variables.framework.applicationKey].subsystems = { };
			} else {
				// must be first request so we need to set up the entire structure
				isReload = false;
				framework.cache = frameworkCache;
				framework.subsystems = { };
				framework.subsystemFactories = { }; 
				application[variables.framework.applicationKey] = framework;
			}
		}
		
		// this will recreate the main bean factory on a reload:
		setupApplication();
		
		if ( isReload ) {
			/*
				it's possible that the cache got populated by another thread between resetting the cache above
				and the factory getting recreated by the user code in setupApplication() so we flush the cache
				again here to be safe / paranoid! 
			*/
			frameworkCache = { };
			frameworkCache.lastReload = now();
			frameworkCache.fileExists = { };
			frameworkCache.controllers = { };
			frameworkCache.services = { };
			application[variables.framework.applicationKey].cache = frameworkCache;
			application[variables.framework.applicationKey].subsystems = { };
		}
	
	}
	
	private void function setupFrameworkDefaults() {

		// default values for Application::variables.framework structure:
		if ( !structKeyExists(variables, 'framework') ) {
			variables.framework = { };
		}
		if ( !structKeyExists(variables.framework, 'action') ) {
			variables.framework.action = 'action';
		}
		if ( !structKeyExists(variables.framework, 'base') ) {
			variables.framework.base = getDirectoryFromPath( variables.cgiScriptName );
		} else if ( right( variables.framework.base, 1 ) != '/' ) {
			variables.framework.base = variables.framework.base & '/';
		}
		variables.framework.base = replace( variables.framework.base, chr(92), '/', 'all' );
		if ( !structKeyExists(variables.framework, 'cfcbase') ) {
			if ( len( variables.framework.base ) eq 1 ) {
				variables.framework.cfcbase = '';
			} else {
				variables.framework.cfcbase = replace( mid( variables.framework.base, 2, len(variables.framework.base)-2 ), '/', '.', 'all' );
			}
		}
		if ( !structKeyExists(variables.framework, 'usingSubsystems') ) {
			variables.framework.usingSubsystems = false;
		}
		if ( !structKeyExists(variables.framework, 'defaultSubsystem') ) {
			variables.framework.defaultSubsystem = 'home';
		}
		if ( !structKeyExists(variables.framework, 'defaultSection') ) {
			variables.framework.defaultSection = 'main';
		}
		if ( !structKeyExists(variables.framework, 'defaultItem') ) {
			variables.framework.defaultItem = 'default';
		}
		if ( !structKeyExists(variables.framework, 'subsystemDelimiter') ) {
			variables.framework.subsystemDelimiter = ':';
		}
		if ( !structKeyExists(variables.framework, 'siteWideLayoutSubsystem') ) {
			variables.framework.siteWideLayoutSubsystem = 'common';
		}
		if ( !structKeyExists(variables.framework, 'home') ) {
			if (usingSubsystems()) {
				variables.framework.home = variables.framework.defaultSubsystem & variables.framework.subsystemDelimiter & variables.framework.defaultSection & '.' & variables.framework.defaultItem;
			} else {
				variables.framework.home = variables.framework.defaultSection & '.' & variables.framework.defaultItem;
			}
		}
		if ( !structKeyExists(variables.framework, 'error') ) {
			if (usingSubsystems()) {
				variables.framework.error = variables.framework.defaultSubsystem & variables.framework.subsystemDelimiter & variables.framework.defaultSection & '.error';
			} else {
				variables.framework.error = variables.framework.defaultSection & '.error';
			}
		}
		if ( !structKeyExists(variables.framework, 'reload') ) {
			variables.framework.reload = 'reload';
		}
		if ( !structKeyExists(variables.framework, 'password') ) {
			variables.framework.password = 'true';
		}
		if ( !structKeyExists(variables.framework, 'reloadApplicationOnEveryRequest') ) {
			variables.framework.reloadApplicationOnEveryRequest = false;
		}
		if ( !structKeyExists(variables.framework, 'preserveKeyURLKey') ) {
			variables.framework.preserveKeyURLKey = 'fw1pk';
		}
		if ( !structKeyExists(variables.framework, 'maxNumContextsPreserved') ) {
			variables.framework.maxNumContextsPreserved = 10;
		}
		if ( !structKeyExists(variables.framework, 'baseURL') ) {
			variables.framework.baseURL = 'useCgiScriptName';
		}
		if ( !structKeyExists(variables.framework, 'generateSES') ) {
			variables.framework.generateSES = false;
		}
		if ( !structKeyExists(variables.framework, 'SESOmitIndex') ) {
			variables.framework.SESOmitIndex = false;
		}
		// NOTE: unhandledExtensions is a list of file extensions that are not handled by FW/1
		if ( !structKeyExists(variables.framework, 'unhandledExtensions') ) {
			variables.framework.unhandledExtensions = 'cfc';
		}
		// NOTE: you can provide a comma delimited list of paths.  Since comma is the delim, it can not be part of your path URL to exclude
		if ( !structKeyExists(variables.framework, 'unhandledPaths') ) {
			variables.framework.unhandledPaths = '/flex2gateway';
		}				
		// convert unhandledPaths to regex:
		variables.framework.unhandledPathRegex = replaceNoCase(
			REReplace( variables.framework.unhandledPaths, '(\+|\*|\?|\.|\[|\^|\$|\(|\)|\{|\||\\)', '\\\1', 'all' ),
			',', '|', 'all' );
		if ( !structKeyExists(variables.framework, 'applicationKey') ) {
			variables.framework.applicationKey = 'org.corfield.framework';
		}
		if ( !structKeyExists( variables.framework, 'suppressImplicitService' ) ) {
			variables.framework.suppressImplicitService = true;
		}
		if ( !structKeyExists( variables.framework, 'cacheFileExists' ) ) {
			variables.framework.cacheFileExists = false;
		}
		if ( !structKeyExists( variables.framework, 'routes' ) ) {
			variables.framework.routes = [ ];
		}
		if ( !structKeyExists( variables.framework, 'noLowerCase' ) ) {
			variables.framework.noLowerCase = false;
		}
		if ( !structKeyExists( variables.framework, 'subsystems' ) ) {
			variables.framework.subsystems = { };
		}
		variables.framework.version = '2.0.1';
	}

	private void function setupRequestDefaults() {
		request.base = variables.framework.base;
		request.cfcbase = variables.framework.cfcbase;
	}

	private void function setupRequestWrapper( boolean runSetup ) {

		request.subsystem = getSubsystem( request.action );
		request.subsystembase = request.base & getSubsystemDirPrefix( request.subsystem );
		request.section = getSection( request.action );
		request.item = getItem( request.action );
		request.services = [ ];
		
		if ( runSetup ) {
			rc = request.context;
			controller( variables.magicApplicationController & '.' & variables.magicApplicationAction );
			setupSubsystemWrapper( request.subsystem );
			setupRequest();
		}

		controller( request.action );
		if ( !variables.framework.suppressImplicitService ) {
			service( request.action, getServiceKey( request.action ), { }, false );
		}
	}

	private void function setupResponseWrapper() {
		setupResponse();
	}

	private void function setupSessionWrapper() {
		setupSession();
	}

	private void function setupSubsystemWrapper( string subsystem ) {
		if ( !usingSubsystems() ) return;
		lock name="fw1_#application.applicationName#_#variables.framework.applicationKey#_subsysteminit_#subsystem#" type="exclusive" timeout="30" {
			if ( !isSubsystemInitialized( subsystem ) ) {
				application[ variables.framework.applicationKey ].subsystems[ subsystem ] = now();
				setupSubsystem( subsystem );
			}
		}
	}

	private string function validateAction( string action ) {
		// check for forward and backward slash in the action - using chr() to avoid confusing TextMate (Hi Nathan!)
		if ( findOneOf( chr(47) & chr(92), action ) > 0 ) {
			raiseException( type="FW1.actionContainsSlash", message="Found a slash in the action: '#action#'.",
					detail="Actions are not allowed to embed sub-directory paths.");
		}
		return action;
	}

	private void function viewNotFound() {
		raiseException( type="FW1.viewNotFound", message="Unable to find a view for '#request.action#' action.",
				detail="'#request.missingView#' does not exist." );
	}
	
}
