component {
    variables._fw1_version = "2.5_snapshot";
/*
	Copyright (c) 2009-2014, Sean Corfield, Marcin Szczepanski, Ryan Cogswell

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
	request._fw1 = {
        cgiScriptName = CGI.SCRIPT_NAME,
        cgiRequestMethod = CGI.REQUEST_METHOD,
        controllers = [ ],
        requestDefaultsInitialized = false,
        services = [ ],
        doTrace = false,
        trace = [ ]
    };
	// do not rely on these, they are meant to be true magic...
    variables.magicApplicationSubsystem = '][';
	variables.magicApplicationController = '[]';
	variables.magicApplicationAction = '__';
	variables.magicBaseURL = '-[]-';
	
	public void function abortController() {
		request._fw1.abortController = true;
        internalFrameworkTrace( 'abortController() called' );
		throw( type='FW1.AbortControllerException', message='abortController() called' );
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
     * buildCustomURL() can be used to construct routes by appending the given URI
     * to a resolvedBaseURL() value
     */
    public string function buildCustomURL( string uri ) {
        var baseData = resolveBaseURL();
        return baseData.path & uri;
    }
	
	/*
	 *	buildURL() should be used from views to construct urls when using subsystems or
	 *	in order to provide a simpler transition to using subsystems in the future
	 */
	public string function buildURL( string action = '.', string path = variables.magicBaseURL, any queryString = '' ) {
		if ( action == '.' ) {
            action = getFullyQualifiedAction();
        } else if ( left( action, 2 ) == '.?' ) {
            action = replace( action, '.', getFullyQualifiedAction() );
        }
        var pathData = resolveBaseURL( action, path );
        path = pathData.path;
		var omitIndex = pathData.omitIndex;
		// if queryString is a struct, massage it into a string
		if ( isStruct( queryString ) && structCount( queryString ) ) {
			var q = '';
			for( var key in queryString ) {
				if( isSimpleValue( queryString[key] ) ){
					q &= '#urlEncodedFormat( key )#=#urlEncodedFormat( queryString[ key ] )#&';
				}
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
                if ( q < len( action ) ) {
				    queryString = right( action, len( action ) - q );
                }
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
		} else if ( structKeyExists( request._fw1, 'generateSES' ) && request._fw1.generateSES ) {
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

		if ( structKeyExists( request._fw1, 'controllerExecutionStarted' ) ) {
			raiseException( type='FW1.controllerExecutionStarted', message="Controller '#action#' may not be added at this point.",
				detail='The controller execution phase has already started. Controllers may not be added by other controller methods.' );
		}

		tuple.controller = getController( section = section, subsystem = subsystem );
		tuple.key = subsystem & variables.framework.subsystemDelimiter & section;
        tuple.subsystem = subsystem;
        tuple.section = section;
		tuple.item = item;

		if ( structKeyExists( tuple, 'controller' ) && isObject( tuple.controller ) && !isNull(tuple.controller)) {
            internalFrameworkTrace( 'queuing controller', subsystem, section, item );
			arrayAppend( request._fw1.controllers, tuple );
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
     * call this to disable tracing, e.g., from setupTraceRender()
     */
    public void function disableFrameworkTrace() {
        request._fw1.doTrace = false;
    }

    /*
     * call this to (re-)enable tracing
     */
    public void function enableFrameworkTrace() {
        request._fw1.doTrace = true;
    }

    public void function frameworkTrace( string message ) {
        if ( request._fw1.doTrace ) {
            try {
                if ( isDefined( 'session._fw1_trace' ) &&
                     structKeyExists( session, '_fw1_trace' ) ) {
                    request._fw1.trace = session._fw1_trace;
                    structDelete( session, '_fw1_trace' );
                }
            } catch ( any _ ) {
                // ignore if session is not enabled
            }
            var trace = { tick = getTickCount(), msg = message,
                          sub = '', s = '', i = '' };
            if ( arrayLen( arguments ) > 1 ) {
                trace.v = arguments[2];
            }
            arrayAppend( request._fw1.trace, trace );
        }
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
			raiseException( type='FW1.subsystemNotSpecified', message='No subsystem specified and no default configured.',
					detail='When using subsystems, every request should specify a subsystem or variables.framework.defaultSubsystem should be configured.' );
		}

		return variables.framework.defaultSubsystem;

	}
	
    /*
     * override this to provide your environment selector
     */
    public string function getEnvironment() {
        return '';
    }

    /*
     * return the contents of the framework trace array (if you wish to process the
     * trace data yourself either prior to display or instead of display - in which
     * case call disableFrameworkTrace() to prevent display).
     */
    public array function getFrameworkTrace() {
        return request._fw1.trace;
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
     * return the local hostname of the server
     */
    public string function getHostname() {
        return createObject( 'java', 'java.net.InetAddress' ).getLocalHost().getHostName();
    }
	
	/*
	 * return the item part of the action
	 */
	public string function getItem( string action = request.action ) {
		return listLast( getSectionAndItem( action ), '.' );
	}
    
    
    /*
     * return the current request context structure
	 */
    public struct function getRC() {
        return request.context;
    }
	
    /*
     * return the specified property from the request context or a default value
	 */
    public any function getRCValue( string propName, any defaultValue = '' ) {
        if ( structKeyExists( request, 'context' ) &&
             structKeyExists( request.context, propName ) ) {
            return request.context[ propName ];
        } else {
            return defaultValue;
        }
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
	 * return the resource route templates
	 */
	public array function getResourceRouteTemplates() {
		return variables.framework.resourceRouteTemplates;
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
     * return the base directory for the current request's subsystem
     */
    public string function getSubsystemBase() {
        return request.subsystemBase;
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
     * returns true if the specified action matches the currently
     * executing action (after both have been expanded)
     */
    public boolean function isCurrentAction( string action ) {
        return getFullyQualifiedAction( action ) ==
            getFullyQualifiedAction();
    }

	/*
	 * layout() may be invoked inside layouts
	 * returns the UI generated by the named layout and body
	 */
	public string function layout( string path, string body ) {
		var layoutPath = parseViewOrLayoutPath( path, 'layout' );
        internalFrameworkTrace( 'layout( #path# ) called - rendering #layoutPath#' );
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
		    if ( !structKeyExists( variables, 'framework' ) ||
                 !structKeyExists( variables.framework, 'version' ) ) {
		      // error occurred before framework was initialized
		      failure( exception, event, false, true );
		      return;
		    }
		    
			// record details of the exception:
			if ( structKeyExists( request, 'action' ) ) {
				request.failedAction = request.action;
			}
			request.exception = exception;
			request.event = event;
			// reset lifecycle flags:
            structDelete( request, 'layout' );
			structDelete( request._fw1, 'controllerExecutionComplete' );
			structDelete( request._fw1, 'controllerExecutionStarted' );
			structDelete( request._fw1, 'serviceExecutionComplete' );
			structDelete( request._fw1, 'overrideViewAction' );
            if ( structKeyExists( request._fw1, 'renderData' ) ) {
                // need to reset the content type as well!
                try {
                    getPageContext().getResponse().setContentType( 'text/html; charset=utf-8' );
                } catch ( any e ) {
                    // but ignore any exceptions
                }
                structDelete( request._fw1, 'renderData' );
            }
			// setup the new controller action, based on the error action:
			request._fw1.controllers = [ ];
            // reset services for this new action:
            request._fw1.services = [ ];
			
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
			if ( !structKeyExists( request, 'base' ) ) {
				if ( structKeyExists( variables, 'framework' ) && structKeyExists( variables.framework, 'base' ) ) {
					request.base = variables.framework.base;
				} else {
					request.base = '';
				}
			}
			if ( !structKeyExists( request, 'cfcbase' ) ) {
				if ( structKeyExists( variables, 'framework' ) && structKeyExists( variables.framework, 'cfcbase' ) ) {
					request.cfcbase = variables.framework.cfcbase;
				} else {
					request.cfcbase = '';
				}
			}
			internalFrameworkTrace( 'onError( #exception.message#, #event# ) called' );
			setupRequestWrapper( false );
			onRequest( '' );
            frameworkTraceRender();
		} catch ( any e ) {
			failure( e, 'onError' );
			failure( exception, event, true );
            frameworkTraceRender();
		}

	}

	/*
	 * this can be overridden if you want to change the behavior when
	 * FW/1 cannot find a matching view
	 */
	public string function onMissingView( struct rc ) {
		// unable to find a matching view - fail with a nice exception
		viewNotFound();
		// if we got here, we would return the string to be rendered
		// but viewNotFound() throws an exception...
        // for example, return view( 'main.missing' );
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

		request._fw1.controllerExecutionStarted = true;
		try {
			n = arrayLen( request._fw1.controllers );
			for ( i = 1; i <= n; i = i + 1 ) {
				tuple = request._fw1.controllers[ i ];
				// run before once per controller:
				if ( !structKeyExists( once, tuple.key ) ) {
					once[ tuple.key ] = i;
					doController( tuple, 'before', 'before' );
					if ( structKeyExists( request._fw1, 'abortController' ) ) abortController();
				}
				doController( tuple, 'start' & tuple.item, 'start' );
				if ( structKeyExists( request._fw1, 'abortController' ) ) abortController();
				doController( tuple, tuple.item, 'item' );
				if ( structKeyExists( request._fw1, 'abortController' ) ) abortController();
			}
			n = arrayLen( request._fw1.services );
			for ( i = 1; i <= n; i = i + 1 ) {
				tuple = request._fw1.services[ i ];
				if ( tuple.key == '' ) {
					// throw the result away:
					doService( tuple, tuple.item, tuple.args, tuple.enforceExistence );
					if ( structKeyExists( request._fw1, 'abortController' ) ) abortController();
				} else {
					_data_fw1 = doService( tuple, tuple.item, tuple.args, tuple.enforceExistence );
					if ( structKeyExists( request._fw1, 'abortController' ) ) abortController();
					if ( isDefined('_data_fw1') ) {
                        internalFrameworkTrace( 'store service result in rc.#tuple.key#', tuple.subsystem, tuple.section, tuple.item );
						request.context[ tuple.key ] = _data_fw1;
					} else {
                        internalFrameworkTrace( 'service returned no result for rc.#tuple.key#', tuple.subsystem, tuple.section, tuple.item );
                    }
				}
			}
			request._fw1.serviceExecutionComplete = true;
			n = arrayLen( request._fw1.controllers );
			for ( i = n; i >= 1; i = i - 1 ) {
				tuple = request._fw1.controllers[ i ];
				doController( tuple, 'end' & tuple.item, 'end' );
				if ( structKeyExists( request._fw1, 'abortController' ) ) abortController();
				if ( once[ tuple.key ] eq i ) {
					doController( tuple, 'after', 'after' );
					if ( structKeyExists( request._fw1, 'abortController' ) ) abortController();
				}
			}
		} catch ( FW1.AbortControllerException e ) {
			request._fw1.serviceExecutionComplete = true;
		}
		request._fw1.controllerExecutionComplete = true;

        if ( structKeyExists( request._fw1, 'renderData' ) ) {
            out = renderDataWithContentType();
        } else {
		    buildViewQueue();
            internalFrameworkTrace( 'setupView() called' );
		    setupView( rc = request.context );
		    if ( structKeyExists(request._fw1, 'view') ) {
                internalFrameworkTrace( 'rendering #request._fw1.view#' );
			    out = internalView( request._fw1.view );
		    } else if ( structKeyExists(request._fw1, 'omvInProgress') ) {
                internalFrameworkTrace( 'viewNotFound() called' );
                viewNotFound();
            } else {
                request._fw1.omvInProgress = true;
                internalFrameworkTrace( 'onMissingView() called' );
			    out = onMissingView( request.context );
		    }
            
            buildLayoutQueue();
		    for ( i = 1; i <= arrayLen(request._fw1.layouts); i = i + 1 ) {
			    if ( structKeyExists(request, 'layout') && !request.layout ) {
                    internalFrameworkTrace( 'aborting layout rendering' );
				    break;
			    }
                internalFrameworkTrace( 'rendering #request._fw1.layouts[i]#' );
			    out = internalLayout( request._fw1.layouts[i], out );
		    }
        }
		writeOutput( out );
		setupResponseWrapper();
	}

    /*
     * if you override onRequestEnd(), call super.onRequestEnd() if you
     * want tracing functionality to continue working
     */
    public any function onRequestEnd() {
        frameworkTraceRender();
    }

	/*
	 * it is better to set up your request configuration in
	 * your setupRequest() method
	 * if you do override onRequestStart(), you must call
	 * super.onRequestStart() first
	 */
	public any function onRequestStart( string targetPath ) {
		setupFrameworkDefaults();
		setupRequestDefaults();

		if ( !isFrameworkInitialized() || isFrameworkReloadRequest() ) {
			setupApplicationWrapper();
		}

		restoreFlashContext();
		// ensure flash context cannot override request action:
		request.context[variables.framework.action] = request.action;

		// allow configured extensions and paths to pass through to the requested template.
		// NOTE: for unhandledPaths, we make the list into an escaped regular expression so we match on subdirectories.  
		// Meaning /myexcludepath will match '/myexcludepath' and all subdirectories  
		if ( listFindNoCase( variables.framework.unhandledExtensions, listLast( targetPath, '.' ) ) || 
				REFindNoCase( '^(' & variables.framework.unhandledPathRegex & ')', targetPath ) ) {		
			structDelete(this, 'onRequest');
			structDelete(variables, 'onRequest');
			structDelete(this, 'onRequestEnd');
			structDelete(variables, 'onRequestEnd');			
            if ( !variables.framework.unhandledErrorCaught ) {
			    structDelete(this, 'onError');
			    structDelete(variables, 'onError');
            }
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
		setupSessionWrapper();
	}
	
	// populate() may be invoked inside controllers
	public any function populate( any cfc, string keys = '', boolean trustKeys = false, boolean trim = false, boolean deep = false, any properties = '' ) {
        var props = isSimpleValue( properties ) ? request.context : properties;
		if ( keys == '' ) {
			if ( trustKeys ) {
				// assume every property can be set into the CFC
				for ( var property in props ) {
					try {
						var args = { };
						args[ property ] = props[ property ];
						if ( trim && isSimpleValue( args[ property ] ) ) args[ property ] = trim( args[ property ] );
						// cfc[ 'set'&property ]( argumentCollection = args ); // ugh! no portable script version of this?!?!						
						setProperty( cfc, property, args );
					} catch ( any e ) {
						onPopulateError( cfc, property, props );
					}
				}
			} else {
				var setters = findImplicitAndExplicitSetters( cfc );
				for ( var property in setters ) {
					if ( structKeyExists( props, property ) ) {
						var args = { };
						args[ property ] = props[ property ];
						if ( trim && isSimpleValue( args[ property ] ) ) args[ property ] = trim( args[ property ] );
						// cfc[ 'set'&property ]( argumentCollection = args ); // ugh! no portable script version of this?!?!
						setProperty( cfc, property, args );
					} else if ( deep && structKeyExists( cfc, 'get' & property ) ) {
						// look for a property that starts with the property
						for ( var key in props ) {
							if ( listFindNoCase( key, property, '.') ) {
								try {
									setProperty( cfc, key, { '#key#' = props[ key ] } );
								} catch ( any e ) {
									onPopulateError( cfc, key, props );
								}
							}
						}
					}
				}
			}
		} else {
			var setters = findImplicitAndExplicitSetters( cfc );
			var keyArray = listToArray( keys );
			for ( var property in keyArray ) {
				var trimProperty = trim( property );
				if ( structKeyExists( setters, trimProperty ) || trustKeys ) {
					if ( structKeyExists( props, trimProperty ) ) {
						var args = { };
						args[ trimProperty ] = props[ trimProperty ];
						if ( trim && isSimpleValue( args[ trimProperty ] ) ) args[ trimProperty ] = trim( args[ trimProperty ] );
						// cfc[ 'set'&trimproperty ]( argumentCollection = args ); // ugh! no portable script version of this?!?!
						setProperty( cfc, trimProperty, args );
					}
				} else if ( deep ) {
					if ( listLen( trimProperty, '.' ) > 1 ) {
						var prop = listFirst( trimProperty, '.' );
						if ( structKeyExists( cfc, 'get' & prop ) ) {
                            setProperty( cfc, trimProperty, { '#trimProperty#' = props[ trimProperty ] } );
                        }
					}
				}
			}
		}
		return cfc;
	}

	private void function setProperty( struct cfc, string property, struct args ) {
		if ( listLen( property, '.' ) > 1 ) {
			var firstObjName = listFirst( property, '.' );
			var newProperty = listRest( property,  '.' );

			args[ newProperty ] = args[ property ];
			structDelete( args, property );

			if ( structKeyExists( cfc , 'get' & firstObjName ) ) {
				var obj = getProperty( cfc, firstObjName );
				if ( !isNull( obj ) ) setProperty( obj, newProperty, args );
			}
		} else {
			evaluate( 'cfc.set#property#( argumentCollection = args )' );
		}
	}
	
	private any function getProperty( struct cfc, string property ) {
		if ( structKeyExists( cfc, 'get#property#' ) ) return evaluate( 'cfc.get#property#()' );
	}

	// call from your controller to redirect to a clean URL based on an action, pushing data to flash scope if necessary:
	public void function redirect( string action, string preserve = 'none', string append = 'none', string path = variables.magicBaseURL, string queryString = '', string statusCode = '302' ) {
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
        if ( request._fw1.doTrace ) {
            internalFrameworkTrace( 'redirecting to #targetURL# (#statusCode#)' );
            try {
                session._fw1_trace = request._fw1.trace;
            } catch ( any _ ) {
                // ignore exception if session is not enabled
            }
        }
		location( targetURL, false, statusCode );
	}

    // call this to render data rather than a view and layouts
    public void function renderData( string type, any data, numeric statusCode = 200 ) {
        request._fw1.renderData = { type = type, data = data, statusCode = statusCode };
    }
	
	// call this from your controller to queue up additional services
	public void function service( string action, string key, struct args = { }, boolean enforceExistence = true ) {
        deprecated( variables.framework.suppressServiceQueue,
                    "service() call requires suppressServiceQueue = false" );
		var subsystem = getSubsystem( action );
		var section = getSection( action );
		var item = getItem( action );
		var tuple = { };

		if ( structKeyExists( request._fw1, 'serviceExecutionComplete' ) ) {
			raiseException( type='FW1.serviceExecutionComplete', message="Service '#action#' may not be added at this point.",
				detail='The service execution phase is complete. Services may not be added by end*() or after() controller methods.' );
		}

		tuple.service = getService(section=section, subsystem=subsystem);
        tuple.subsystem = subsystem;
        tuple.section = section;
		tuple.item = item;
		tuple.key = key;
		tuple.args = args;
		tuple.enforceExistence = enforceExistence;

		if ( structKeyExists( tuple, 'service' ) && isObject( tuple.service ) ) {
            internalFrameworkTrace( 'queuing service', subsystem, section, item );
			arrayAppend( request._fw1.services, tuple );
		} else if ( enforceExistence ) {
			raiseException( type='FW1.serviceCfcNotFound', message="Service '#action#' does not exist.",
				detail="To have the execution of this service be conditional based upon its existence, pass in a fourth parameter (or enforceExistence if using named arguments) of 'false'." );
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
		request._fw1.overrideLayoutAction = validateAction( action );
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
	 * override this to provide environment-specific initialization
	 * you do not need to call super.setupEnvironment()
	 */
	public void function setupEnvironment( string env ) { }

	/*
	 * override this to provide request-specific initialization
	 * you do not need to call super.setupRequest()
	 */
	public void function setupRequest() { }

	/*
	 * override this to provide request-specific finalization
	 * you do not need to call super.setupResponse()
	 */
	public void function setupResponse( struct rc ) { }

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
     * override this if you wish to intercept the tracing logic
     * and handle it yourself - you can 
     */
    public void function setupTraceRender() { }
	
	/*
	 * override this to provide pre-rendering logic, e.g., to
	 * populate the request context with globally required data
	 * you do not need to call super.setupView()
	 */
	public void function setupView( struct rc ) { }
	
	/*
	 * use this to override the default view
	 */
	public void function setView( string action ) {
		request._fw1.overrideViewAction = validateAction( action );
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
	public string function view( string path, struct args = { },
                                 any missingView = { } ) {
		var viewPath = parseViewOrLayoutPath( path, 'view' );
        if ( cachedFileExists( viewPath ) ) {
            internalFrameworkTrace( 'view( #path# ) called - rendering #viewPath#' );
		    return internalView( viewPath, args );
        } else if ( isSimpleValue( missingView ) ) {
            return missingView;
		} else if ( structKeyExists(request._fw1, 'omvInProgress') ) {
            internalFrameworkTrace( 'view( #path# ) called - viewNotFound() called' );
            viewNotFound();
        } else {
            request._fw1.omvInProgress = true;
            internalFrameworkTrace( 'view( #path# ) called - onMissingView() called' );
            return onMissingView( request.context );
        }
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
	
	private void function buildLayoutQueue() {
		var siteWideLayoutBase = request.base & getSubsystemDirPrefix( variables.framework.siteWideLayoutSubsystem );
		var testLayout = 0;
		// default behavior:
		var subsystem = request.subsystem;
		var section = request.section;
		var item = request.item;
		var subsystembase = '';
		
		request._fw1.layouts = [ ];
		
		// has layout been overridden?
		if ( structKeyExists( request._fw1, 'overrideLayoutAction' ) ) {
			subsystem = getSubsystem( request._fw1.overrideLayoutAction );
			section = getSection( request._fw1.overrideLayoutAction );
			item = getItem( request._fw1.overrideLayoutAction );
			structDelete( request._fw1, 'overrideLayoutAction' );
		}
		subsystembase = request.base & getSubsystemDirPrefix( subsystem );
        internalFrameworkTrace( 'building layout queue', subsystem, section, item );
		// look for item-specific layout:
		testLayout = parseViewOrLayoutPath( subsystem & variables.framework.subsystemDelimiter &
													section & '/' & item, 'layout' );
		if ( cachedFileExists( testLayout ) ) {
            internalFrameworkTrace( 'found item-specific layout #testLayout#', subsystem, section, item );
			arrayAppend( request._fw1.layouts, testLayout );
        }
		// look for section-specific layout:
		testLayout = parseViewOrLayoutPath( subsystem & variables.framework.subsystemDelimiter &
													section, 'layout' );
		if ( cachedFileExists( testLayout ) ) {
            internalFrameworkTrace( 'found section-specific layout #testLayout#', subsystem, section, item );
			arrayAppend( request._fw1.layouts, testLayout );
		}
		// look for subsystem-specific layout (site-wide layout if not using subsystems):
		if ( request.section != 'default' ) {
			testLayout = parseViewOrLayoutPath( subsystem & variables.framework.subsystemDelimiter &
														'default', 'layout' );
			if ( cachedFileExists( testLayout ) ) {
                internalFrameworkTrace( 'found default layout #testLayout#', subsystem, section, item );
				arrayAppend( request._fw1.layouts, testLayout );
			}
		}
		// look for site-wide layout (only applicable if using subsystems)
		if ( usingSubsystems() && siteWideLayoutBase != subsystembase ) {
			testLayout = parseViewOrLayoutPath( variables.framework.siteWideLayoutSubsystem & variables.framework.subsystemDelimiter &
														'default', 'layout' );
			if ( cachedFileExists( testLayout ) ) {
                internalFrameworkTrace( 'found #variables.framework.siteWideLayoutSubsystem# layout #testLayout#', subsystem, section, item );
				arrayAppend( request._fw1.layouts, testLayout );
			}
		}
	}


	private void function buildViewQueue() {
		// default behavior:
		var subsystem = request.subsystem;
		var section = request.section;
		var item = request.item;
		var subsystembase = '';
		
		// has view been overridden?
		if ( structKeyExists( request._fw1, 'overrideViewAction' ) ) {
			subsystem = getSubsystem( request._fw1.overrideViewAction );
			section = getSection( request._fw1.overrideViewAction );
			item = getItem( request._fw1.overrideViewAction );
			structDelete( request._fw1, 'overrideViewAction' );
		}
		subsystembase = request.base & getSubsystemDirPrefix( subsystem );
        internalFrameworkTrace( 'building view queue', subsystem, section, item );
		// view and layout setup - used to be in setupRequestWrapper():
		request._fw1.view = parseViewOrLayoutPath( subsystem & variables.framework.subsystemDelimiter &
													section & '/' & item, 'view' );
		if ( cachedFileExists( request._fw1.view ) ) {
            internalFrameworkTrace( 'found view #request._fw1.view#', subsystem, section, item );
        } else {
            internalFrameworkTrace( 'no such view #request._fw1.view#', subsystem, section, item );
			request.missingView = request._fw1.view;
			// ensures original view not re-invoked for onError() case:
			structDelete( request._fw1, 'view' );
		}
	}


	private boolean function cachedFileExists( string filePath ) {
		var cache = application[ variables.framework.applicationKey ].cache;
		if ( !variables.framework.cacheFileExists ) {
			return fileExists( expandPath( filePath) );
		}
		param name="cache.fileExists" default="#{ }#";
		if ( !structKeyExists( cache.fileExists, filePath ) ) {
			cache.fileExists[ filePath ] = fileExists( expandPath( filePath ) );
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

    private void function deprecated( boolean throwit, string message ) {
        if ( throwit ) {
            throw( type="FW1.Deprecated",
                   message="Deprecated: #message#",
                   detail="This feature is deprecated: you need to configure FW/1 to allow it (or update your code)." );
        } else {
            var out = createObject( "java", "java.lang.System" ).out;
            out.println( "FW/1: DEPRECATED: " & message );
        }
    }
	
	private void function doController( struct tuple, string method, string lifecycle ) {
        var cfc = tuple.controller;
        if ( lifecycle == "start" ||
             lifecycle == "end" ) {
            if ( structKeyExists( cfc, method ) ) {
                deprecated( variables.framework.suppressServiceQueue,
                            "start/end methods require suppressServiceQueue = false" );
            }
            if ( variables.framework.suppressServiceQueue ) return;
        }
		if ( structKeyExists( cfc, method ) ) {
			try {
                internalFrameworkTrace( 'calling #lifecycle# controller', tuple.subsystem, tuple.section, method );
				evaluate( 'cfc.#method#( rc = request.context )' );
			} catch ( any e ) {
				setCfcMethodFailureInfo( cfc, method );
				rethrow;
			}
		} else if ( structKeyExists( cfc, 'onMissingMethod' ) ) {
			try {
                internalFrameworkTrace( 'calling #lifecycle# controller (via onMissingMethod)', tuple.subsystem, tuple.section, method );
				evaluate( 'cfc.#method#( rc = request.context, method = lifecycle )' );
			} catch ( any e ) {
				setCfcMethodFailureInfo( cfc, method );
				rethrow;
			}
		} else {
            internalFrameworkTrace( 'no #lifecycle# controller to call', tuple.subsystem, tuple.section, method );
        }
	}
	
	private any function doService( struct tuple, string method, struct args, boolean enforceExistence ) {
        var cfc = tuple.service;
		if ( structKeyExists( cfc, method ) || structKeyExists( cfc, 'onMissingMethod' ) ) {
			try {
				structAppend( args, request.context, false );
                internalFrameworkTrace( 'calling service', tuple.subsystem, tuple.section, method );
				var _result_fw1 = evaluate( 'cfc.#method#( argumentCollection = args )' );
				if ( !isNull( _result_fw1 ) ) {
					return _result_fw1;
				}
			} catch ( any e ) {
				setCfcMethodFailureInfo( cfc, method );
				rethrow;
			}
		} else if ( enforceExistence ) {
			raiseException( type='FW1.serviceMethodNotFound', message="Service method '#method#' does not exist in service '#getMetadata( cfc ).fullname#'.",
				detail="To have the execution of this service method be conditional based upon its existence, pass in a third parameter of 'false'." );
		}
	}
	
	private void function dumpException( any exception ) {
		writeDump( var = exception, label = 'Exception - click to expand', expand = false );
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

	private void function failure( any exception, string event, boolean indirect = false, boolean early = false ) {
		var h = indirect ? 3 : 1;
		if ( structKeyExists(exception, 'rootCause') ) {
			exception = exception.rootCause;
		}
		getPageContext().getResponse().setStatus( 500 );
		if ( early ) {
		    writeOutput( '<h1>Exception occured before FW/1 was initialized</h1>');
		} else {
			writeOutput( '<h#h#>' & ( indirect ? 'Original exception ' : 'Exception' ) & ' in #event#</h#h#>' );
			if ( structKeyExists( request, 'failedAction' ) ) {
				writeOutput( '<p>The action #request.failedAction# failed.</p>' );
			}
			writeOutput( '<h#1+h#>#exception.message#</h#1+h#>' );
		}
		
		writeOutput( '<p>#exception.detail# (#exception.type#)</p>' );
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

    private void function frameworkTraceRender() {
        // do not output trace information if we are rendering data as opposed
        // to rendering HTML views - see #226 and #232
        if ( request._fw1.doTrace &&
             arrayLen( request._fw1.trace ) &&
             !structKeyExists( request._fw1, 'renderData' ) ) {
            setupTraceRender();
        }
        // re-test to allow for setupTraceRender() handling / disabling tracing
        if ( request._fw1.doTrace &&
             arrayLen( request._fw1.trace ) &&
             !structKeyExists( request._fw1, 'renderData' ) ) {
            var startTime = request._fw1.trace[1].tick;
            var font = 'font-family: verdana, helvetica;';
            writeOutput( '<hr /><div style="background: ##ccdddd; color: black; border: 1px solid; border-color: black; padding: 5px; #font#">' );
            writeOutput( '<div style="#font# font-weight: bold; font-size: large; float: left;">Framework Lifecycle Trace</div><div style="clear: both;"></div>' );
            var table = '<table style="border: 1px solid; border-color: black; color: black; #font#" width="100%"><tr><th style="text-align:right;">time</th><th style="text-align:right;">delta</th><th>action</th><th>message</th></tr>';
            writeOutput( table );
            var colors = [ '##ccd4dd', '##ccddcc' ];
            var row = 0;
            var n = arrayLen( request._fw1.trace );
			var lastDuration = 0;
            for ( var i = 1; i <= n; ++i ) {
                var trace = request._fw1.trace[i];
	            var nextTraceTick = i + 1 <= n ? request._fw1.trace[i+1].tick : trace.tick;
                var action = '';
                if ( trace.s == variables.magicApplicationController || trace.sub == variables.magicApplicationSubsystem ) {
                    action = '<em>Application.cfc</em>';
                    if ( right( trace.i, len( variables.magicApplicationAction ) ) == variables.magicApplicationAction ) {
                        continue;
                    }
                } else {
                    action = trace.sub;
                    if ( action != '' && trace.s != '' ) {
                        action &= variables.framework.subsystemDelimiter;
                    }
                    action &= trace.s;
                    if ( trace.s != '' ) {
                        action &= '.';
                    }
                    action &= trace.i;
                }
                ++row;
                writeOutput( '<tr style="border: 0; background: #colors[1 + row mod 2]#;">' );
                writeOutput( '<td style="border: 0; color: black; #font# font-size: small; text-align:right;" width="5%">#trace.tick - starttime#ms</td>' );
	            writeOutput( '<td style="border: 0; color: black; #font# font-size: small; text-align:right;" width="5%">');
	            var duration = nextTraceTick - startTime;
	            if ((duration - lastDuration) > 0) {
		            writeOutput('#duration - lastDuration#ms');
                }
				lastDuration = duration;
				writeOutput('</td>' );
                writeOutput( '<td style="border: 0; color: black; #font# font-size: small;padding-left: 5px;" width="10%">#action#</td>' );
                var color =
                    trace.msg.startsWith( 'no ' ) ? '##cc8888' :
                        trace.msg.startsWith( 'onError( ' ) ? '##cc0000' : '##0000';
                writeOutput( '<td style="border: 0; color: #color#; #font# font-size: small;">#trace.msg#' );
                if ( structKeyExists( trace, 'v' ) ) {
                    writeOutput( '<br />' );
                    writeDump( var = trace.v, expand = false );
                }
                writeOutput( '</td></tr>' );
                if ( trace.msg.startsWith( 'redirecting ' ) ) {
                    writeOutput( '</table>#table#' );
                    if ( i < n ) startTime = request._fw1.trace[i+1].tick;
                }
            }
            writeOutput( '<table></div>' );
        }
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
					} else if ( !usingSubsystems() && hasDefaultBeanFactory() && getDefaultBeanFactory().containsBean( beanName ) ) {
						cfc = getDefaultBeanFactory().getBean( beanName );
					} else {
						if ( type == 'controller' && section == variables.magicApplicationController ) {
							// treat this (Application.cfc) as a controller:
							cfc = this;
						} else if ( cachedFileExists( cfcFilePath( request.cfcbase ) & subsystemDir & types & '/' & section & '.cfc' ) ) {
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
                        if ( type == 'controller' ) injectFramework( cfc );
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
        try {
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
		} catch ( any e ) {
            // ignore - assume session scope is disabled
        }
		var key = getPreserveKeySessionKey( oldKeyToPurge );
		if ( structKeyExists( session, key ) ) {
			structDelete( session, key );
		}
		return nextPreserveKey;
	}
	
	private string function getPreserveKeySessionKey( string preserveKey ) {
		return '__fw1' & preserveKey;
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
		if ( structKeyExists( cfc, 'setFramework' ) || structKeyExists( cfc, 'onMissingMethod' ) ) {
			args.framework = this;
			// allow alternative spellings
			args.fw = this;
			args.fw1 = this;
			evaluate( 'cfc.setFramework( argumentCollection = args )' );
		}
	}
	
    private void function internalFrameworkTrace( string message, string subsystem = '', string section = '', string item = '' ) {
        if ( request._fw1.doTrace ) {
            try {
                if ( isDefined( 'session._fw1_trace' ) &&
                     structKeyExists( session, '_fw1_trace' ) ) {
                    request._fw1.trace = session._fw1_trace;
                    structDelete( session, '_fw1_trace' );
                }
            } catch ( any _ ) {
                // ignore if session is not enabled
            }
            arrayAppend( request._fw1.trace, { tick = getTickCount(), msg = message, sub = subsystem, s = section, i = item } );
        }
    }

	private string function internalLayout( string layoutPath, string body ) {
		var rc = request.context;
		var $ = { };
		// integration point with Mura:
		if ( structKeyExists( rc, '$' ) ) {
			$ = rc.$;
		}
		if ( !structKeyExists( request._fw1, 'controllerExecutionComplete' ) ) {
			raiseException( type='FW1.layoutExecutionFromController', message='Invalid to call the layout method at this point.',
				detail='The layout method should not be called prior to the completion of the controller execution phase.' );
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
		if ( !structKeyExists( request._fw1, 'serviceExecutionComplete') &&
             structKeyExists( request._fw1, 'services' ) && arrayLen( request._fw1.services ) != 0 ) {
			raiseException( type='FW1.viewExecutionFromController', message='Invalid to call the view method at this point.',
				detail='The view method should not be called prior to the completion of the service execution phase.' );
		}
		var response = '';
		savecontent variable="response" {
			include '#viewPath#';
		}
		return response;
	}
	
	private boolean function isFrameworkInitialized() {
		return structKeyExists( variables, 'framework' ) &&
            structKeyExists( application, variables.framework.applicationKey );
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
		var regExCache = isFrameworkInitialized() ? application[ variables.framework.applicationKey ].cache.routes.regex : { };
		var cacheKey = hash( route & target );
		if ( !structKeyExists( regExCache, cacheKey ) ) {
			var routeRegEx = { redirect = false, method = '', pattern = route, target = target };
			// if target has numeric prefix, strip it and set redirect:
			var prefix = listFirst( routeRegEx.target, ':' );
			if ( isNumeric( prefix ) ) {
				routeRegEx.redirect = true;
				routeRegEx.statusCode = prefix;
				routeRegEx.target = listRest( routeRegEx.target, ':' );
			}
			// special routes begin with $METHOD, * is also a wildcard
			var routeLen = len( routeRegEx.pattern );
			if ( routeLen ) {
				if ( left( routeRegEx.pattern, 1 ) == '$' ) {
					// check HTTP method
					routeRegEx.method = listFirst( routeRegEx.pattern, '*/' );
					var methodLen = len( routeRegEx.method );
					if ( routeLen == methodLen ) {
						routeRegEx.pattern = '*';
					} else {
						routeRegEx.pattern = right( routeRegEx.pattern, routeLen - methodLen );
					}
				}
				if ( routeRegEx.pattern == '*' ) {
					routeRegEx.pattern = '/';
				} else if ( right( routeRegEx.pattern, 1 ) != '/' && right( routeRegEx.pattern, 1 ) != '$' ) {
					// only add the closing backslash if last position is not already a "/" or a "$" to respect regex end of string
					routeRegEx.pattern &= '/';
				}
			} else {
				routeRegEx.pattern = '/';
			}
			if ( !len( routeRegEx.target ) || right( routeRegEx.target, 1) != '/' ) routeRegEx.target &= '/';
			// walk for self defined (regex) and :var -  replace :var with ([^/]*) in route and back reference in target:
			var n = 1;
			var placeholders = rematch( '(:[^/]+)|(\([^\)]+)', routeRegEx.pattern );
			for ( var placeholder in placeholders ) {
				if ( left( placeholder, 1 ) == ':') {
					routeRegEx.pattern = replace( routeRegEx.pattern, placeholder, '([^/]*)' );
					routeRegEx.target = replace( routeRegEx.target, placeholder, chr(92) & n );
				}
				++n;
			}
			// add trailing match/back reference: if last character is not "$" to respect regex end of string
			if (right( routeRegEx.pattern, 1 ) != '$')
				routeRegEx.pattern &= '(.*)';
			routeRegEx.target &= chr(92) & n;
			regExCache[ cacheKey ] = routeRegEx;
		}
		// end of preprocessing section
		var routeMatch = { matched = false };
		structAppend( routeMatch, regExCache[ cacheKey ] );
		if ( !len( path ) || right( path, 1) != '/' ) path &= '/';
		var matched = len( routeMatch.method ) ? ( '$' & request._fw1.cgiRequestMethod == routeMatch.method ) : true;
		if ( matched && reFind( routeMatch.pattern, path ) ) {
			routeMatch.matched = true;
			routeMatch.route = route;
			routeMatch.path = path;
		}
		return routeMatch;
	}

	private array function getResourceRoutes( any resourcesToRoute, string subsystem = '', string pathRoot = '', string targetAppend = '' ) {
		var resourceCache = isFrameworkInitialized() ? application[ variables.framework.applicationKey ].cache.routes.resources : { };
		var cacheKey = hash( serializeJSON( resourcesToRoute ) );
		if ( !structKeyExists( resourceCache, cacheKey ) ) {
			// get passed in resourcesToRoute (string,array,struct) to match following struct
			var resources = { resources = [ ], subsystem = subsystem, pathRoot = pathRoot, methods = [ ], nested = [ ] };
			if ( isStruct( resourcesToRoute ) ) {
				structAppend( resources, resourcesToRoute );
				if ( !isArray( resources.resources ) ) resources.resources = listToArray( resources.resources );
				if ( !isArray( resources.methods ) ) resources.methods = listToArray( resources.methods );
				// if this is a recursive (nested) function call, don't let pathRoot or subsystem be overwritten
				if ( len( pathRoot ) ) {
					resources.pathRoot = pathRoot;
					resources.subsystem = subsystem;
				}
			} else {
				resources.resources = isArray( resourcesToRoute ) ? resourcesToRoute : listToArray( resourcesToRoute );
			}
			// create the routes
			var routes = [ ];
			for ( var resource in resources.resources  ) {
				// take possible subsystem into account by qualifying resource name with subsystem name (if necessary)
				var subsystemResource = ( len( resources.subsystem ) && !len( pathRoot ) ? '#resources.subsystem#/' : '' ) & resource;
				var subsystemResourceTarget = ( len( resources.subsystem ) ? '#resources.subsystem##variables.framework.subsystemDelimiter#' : '' ) & resource;
				for ( var routeTemplate in getResourceRouteTemplates() ) {
					// if method names were passed in, only use templates with matching method names
					if ( arrayLen( resources.methods ) && !arrayFindNoCase( resources.methods, routeTemplate.method ) ) continue;
					var routePack = { };
					for ( var httpMethod in routeTemplate.httpMethods ) {
						// build the route
						var route = '#httpMethod##resources.pathRoot#/#subsystemResource#';
						if ( structKeyExists( routeTemplate, 'includeId' ) && routeTemplate.includeId ) route &= '/:id';
						if ( structKeyExists( routeTemplate, 'routeSuffix' ) ) route &= routeTemplate.routeSuffix;
						route &= '/$';
						// build the target
						var target = '/#subsystemResourceTarget#/#routeTemplate.method#';
						if ( structKeyExists( routeTemplate, 'includeId' ) && routeTemplate.includeId ) target &= '/id/:id';
						if ( structKeyExists( routeTemplate, 'targetSuffix' ) ) target &= routeTemplate.targetSuffix;
						target &= targetAppend; 
						routePack[ route ] = target;
					}
					arrayAppend( routes, routePack );
				}
				// nested routes
				var nestedPathRoot = '#resources.pathRoot#/#subsystemResource#/:#resource#_id';
				var nestedTargetAppend = '#targetAppend#/#resource#_id/:#resource#_id';
				var nestedRoutes = getResourceRoutes( resources.nested, resources.subsystem, nestedPathRoot, nestedTargetAppend );
				// wish I could concatenate the arrays...not sure about using java -> routes.addAll( nestedRoutes )
				for ( var nestedPack in nestedRoutes ) {
					arrayAppend( routes, nestedPack );
				}
			}
			resourceCache[ cacheKey ] = routes;
		}
		return resourceCache[ cacheKey ];
	}

	private struct function processRoutes( string path, array routes = getRoutes() ) {
		for ( var routePack in routes ) {
			for ( var route in routePack ) {
				if ( route == 'hint' ) continue;
				if ( route == '$RESOURCES' ) {
					var routeMatch = processRoutes( path, getResourceRoutes( routePack[ route ] ) );
				} else {
					var routeMatch = processRouteMatch( route, routePack[ route ], path );
				}
				if ( routeMatch.matched ) return routeMatch;
			}
		}
		return { matched = false };
	}

	private void function raiseException( string type, string message, string detail ) {
		throw( type = type, message = message, detail = detail );
	}

    private string function renderDataWithContentType() {
        var out = '';
        var contentType = '';
        var type = request._fw1.renderData.type;
        var data = request._fw1.renderData.data;
        var statusCode = request._fw1.renderData.statusCode;
        switch ( type ) {
        case 'json':
            contentType = 'application/json; charset=utf-8';
            out = serializeJSON( data );
            break;
        case 'xml':
            contentType = 'text/xml; charset=utf-8';
            if ( isXML( data ) ) {
                if ( isSimpleValue( data ) ) {
                    // XML as string already
                    out = data;
                } else {
                    // XML object
                    out = toString( data );
                }
            } else {
                throw( type = 'FW1.UnsupportXMLRender',
                       message = 'Data is not XML',
                       detail = 'renderData() called with XML type but unrecognized data format' );
            }
            break;
        case 'text':
            contentType = 'text/plain; charset=utf-8';
            out = data;
            break;
        default:
            throw( type = 'FW1.UnsupportedRenderType',
                   message = 'Only JSON, XML, and TEXT are supported',
                   detail = 'renderData() called with unknown type: ' & type );
            break;
        }
        getPageContext().getResponse().setStatus( statusCode );
        // set the content type header portably:
        getPageContext().getResponse().setContentType( contentType );
        return out;
    }

    private struct function resolveBaseURL( string action = '.', string path = variables.magicBaseURL ) {
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
			path = request._fw1.cgiScriptName;
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
        return { path = path, omitIndex = omitIndex };
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
                    key = trim( key );
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
		frameworkCache.routes = { regex = { }, resources = { } };
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
        internalFrameworkTrace( 'setupApplication() called' );
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
			frameworkCache.routes = { regex = { }, resources = { } };
			application[variables.framework.applicationKey].cache = frameworkCache;
			application[variables.framework.applicationKey].subsystems = { };
		}
	
	}
	
	private void function setupFrameworkDefaults() {

		// default values for Application::variables.framework structure:
		if ( !structKeyExists(variables, 'framework') ) {
			variables.framework = { };
		}
	    variables.framework.version = variables._fw1_version;
        var env = setupFrameworkEnvironments();
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
			variables.framework.usingSubsystems = structKeyExists(variables.framework,'defaultSubsystem') || structKeyExists(variables.framework,'sitewideLayoutSubsystem');
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
		if ( structKeyExists(variables.framework, 'home') ) {
            if (usingSubsystems()) {
                if ( !find( variables.framework.subsystemDelimiter, variables.framework.home ) ) {
                    raiseException( type = "FW1.configuration.home", message = "You are using subsystems but framework.home does not specify a subsystem.", detail = "You should set framework.home to #variables.framework.defaultSubsystem##variables.framework.subsystemDelimiter##variables.framework.home#" );
                }
            }
        } else {
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
        if ( !structKeyExists( variables.framework, 'unhandledErrorCaught' ) ) {
            variables.framework.unhandledErrorCaught = false;
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
		if ( !structKeyExists( variables.framework, 'suppressServiceQueue' ) ) {
			variables.framework.suppressServiceQueue = true;
		}
        if ( !structKeyExists( variables.framework, 'enableGlobalRC' ) ) {
            variables.framework.enableGlobalRC = false;
        }
		if ( !structKeyExists( variables.framework, 'cacheFileExists' ) ) {
			variables.framework.cacheFileExists = false;
		}
		if ( !structKeyExists( variables.framework, 'routes' ) ) {
			variables.framework.routes = [ ];
		}
		if ( !structKeyExists( variables.framework, 'resourceRouteTemplates' ) ) {
			variables.framework.resourceRouteTemplates = [
				{ method = 'default', httpMethods = [ '$GET' ] },
				{ method = 'new', httpMethods = [ '$GET' ], routeSuffix = '/new' },
				{ method = 'create', httpMethods = [ '$POST' ] },
				{ method = 'show', httpMethods = [ '$GET' ], includeId = true },
				{ method = 'update', httpMethods = [ '$PUT','$PATCH' ], includeId = true },
				{ method = 'destroy', httpMethods = [ '$DELETE' ], includeId = true }
			];
		}
		if ( !structKeyExists( variables.framework, 'noLowerCase' ) ) {
			variables.framework.noLowerCase = false;
		}
		if ( !structKeyExists( variables.framework, 'subsystems' ) ) {
			variables.framework.subsystems = { };
		}
		if ( !structKeyExists( variables.framework, 'trace' ) ) {
			variables.framework.trace = false;
		}
        setupEnvironment( env );
        request._fw1.doTrace = variables.framework.trace;
	}

    private string function setupFrameworkEnvironments() {
        var env = getEnvironment();
        if ( structKeyExists( variables.framework, 'environments' ) ) {
            var envs = variables.framework.environments;
            var tier = listFirst( env, '-' );
            if ( structKeyExists( envs, tier ) ) {
                structAppend( variables.framework, envs[ tier ] );
            }
            if ( structKeyExists( envs, env ) ) {
                structAppend( variables.framework, envs[ env ] );
            }
        }
        return env;
    }

	private void function setupRequestDefaults() {
        if ( !request._fw1.requestDefaultsInitialized ) {
            var pathInfo = variables.cgiPathInfo;
            request.base = variables.framework.base;
            request.cfcbase = variables.framework.cfcbase;

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
            var routeMatch = processRoutes( pathInfo );
						if ( routeMatch.matched ) {
							pathInfo = rereplace( routeMatch.path, routeMatch.pattern, routeMatch.target );
							if ( routeMatch.redirect ) {
								location( pathInfo, false, routeMatch.statusCode ); 
							} else {
								request._fw1.route = routeMatch.route;
							}
						}
            try {
                // we use .split() to handle empty items in pathInfo - we fallback to listToArray() on
                // any system that doesn't support .split() just in case (empty items won't work there!)
                if ( len( pathInfo ) > 1 ) {
                    // Strip leading "/" if present.
                    if ( left( pathInfo, 1 ) EQ '/' ) {
                        pathInfo = right( pathInfo, len( pathInfo ) - 1 );
                    }
                    pathInfo = pathInfo.split( '/' );
                } else {
                    pathInfo = arrayNew( 1 );
                }
            } catch ( any exception ) {
                pathInfo = listToArray( pathInfo, '/' );
            }
            var sesN = arrayLen( pathInfo );
            if ( ( sesN > 0 || variables.framework.generateSES ) && getBaseURL() != 'useRequestURI' ) {
                request._fw1.generateSES = true;
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
            request._fw1.requestDefaultsInitialized = true;
        }
	}

	private void function setupRequestWrapper( boolean runSetup ) {

		request.subsystem = getSubsystem( request.action );
		request.subsystembase = request.base & getSubsystemDirPrefix( request.subsystem );
		request.section = getSection( request.action );
		request.item = getItem( request.action );
		
		if ( runSetup ) {
            if ( variables.framework.enableGlobalRC ) {
			    rc = request.context;
            } else {
			    rc = "Update your code to use getRCValue() or " &
                     "set enableGlobalRC to true while you migrate to the new API.";
            }
            if ( usingSubsystems() ) {
			    controller( variables.magicApplicationSubsystem & variables.framework.subsystemDelimiter &
                            variables.magicApplicationController & '.' & variables.magicApplicationAction );
            } else {
			    controller( variables.magicApplicationController & '.' & variables.magicApplicationAction );
            }
			setupSubsystemWrapper( request.subsystem );
            internalFrameworkTrace( 'setupRequest() called' );
			setupRequest();
		}

		controller( request.action );
		if ( !variables.framework.suppressImplicitService ) {
			service( request.action, getServiceKey( request.action ), { }, false );
		}
	}

	private void function setupResponseWrapper() {
        internalFrameworkTrace( 'setupResponse() called' );
		setupResponse( rc = request.context );
	}

	private void function setupSessionWrapper() {
        internalFrameworkTrace( 'setupSession() called' );
		setupSession();
	}

	private void function setupSubsystemWrapper( string subsystem ) {
		if ( !usingSubsystems() ) return;
		lock name="fw1_#application.applicationName#_#variables.framework.applicationKey#_subsysteminit_#subsystem#" type="exclusive" timeout="30" {
			if ( !isSubsystemInitialized( subsystem ) ) {
				application[ variables.framework.applicationKey ].subsystems[ subsystem ] = now();
                internalFrameworkTrace( 'setupSubsystem() called', subsystem );
				setupSubsystem( subsystem );
			}
		}
	}

	private string function validateAction( string action ) {
		// check for forward and backward slash in the action - using chr() to avoid confusing TextMate (Hi Nathan!)
		if ( findOneOf( chr(47) & chr(92), action ) > 0 ) {
			raiseException( type='FW1.actionContainsSlash', message="Found a slash in the action: '#action#'.",
					detail='Actions are not allowed to embed sub-directory paths.');
		}
		return action;
	}

	private void function viewNotFound() {
		raiseException( type='FW1.viewNotFound', message="Unable to find a view for '#request.action#' action.",
				detail="'#request.missingView#' does not exist." );
	}
	
}
