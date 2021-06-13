component {
    variables._fw1_version = "4.3.0";
    /*
      Copyright (c) 2009-2018, Sean Corfield, Marcin Szczepanski, Ryan Cogswell

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
    if ( !structKeyExists( request, '_fw1' ) ) {
        request._fw1 = {
            cgiScriptName = CGI.SCRIPT_NAME,
            cgiPathInfo = CGI.PATH_INFO,
            cgiRequestMethod = CGI.REQUEST_METHOD,
            controllers = [ ],
            requestDefaultsInitialized = false,
            routeMethodsMatched = { },
            doTrace = false,
            trace = [ ]
        };
        if ( len( getContextRoot() ) ) {
            request._fw1.cgiScriptName = replace( CGI.SCRIPT_NAME, getContextRoot(), '' );
            request._fw1.cgiPathInfo = replace( CGI.PATH_INFO, getContextRoot(), '' );
        }
    }
    // do not rely on these, they are meant to be true magic...
    variables.magicApplicationSubsystem = '][';
    variables.magicApplicationController = '[]';
    variables.magicApplicationAction = '__';
    variables.magicBaseURL = '-[]-';

    // constructor if not extended via Application.cfc

    public any function init( struct config = { } ) {
        if ( !structKeyExists( variables, 'framework' ) ) {
            variables.framework = { };
        }
        structAppend( variables.framework, config );
        return this;
    }

    public void function abortController() {
        request._fw1.abortController = true;
        internalFrameworkTrace( 'abortController() called' );
        throw( type='FW1.AbortControllerException', message='abortController() called' );
    }

    public boolean function actionSpecifiesSubsystem( string action ) {
        return find( variables.framework.subsystemDelimiter, action );
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
        uri = replace( uri, chr(92), '/', 'all' );
        var triggers = '[/=&\?]';
        if ( reFind( '#triggers#:', uri ) ) {
            // perform variables substitution from request.context
            var rc = request.context;
            for ( var key in rc ) {
                if ( !isNull( rc[key] ) && isSimpleValue( rc[key] ) ) {
                    uri = REReplaceNoCase( uri, '(#triggers#):#key#', '\1\U\E#rc[key]#', 'all' );
                }
            }
        }
        var baseData = resolveBaseURL();
        if ( len( baseData.path ) && right( baseData.path, 1 ) == '/' &&
             len( uri ) && left( uri, 1 ) == '/' ) {
            if ( len( baseData.path ) == 1 ) baseData.path = '';
            else baseData.path = left( baseData.path, len( baseData.path ) - 1 );
        }
        return baseData.path & uri;
    }

    /*
     *  buildURL() should be used from views to construct urls when using subsystems or
     *  in order to provide a simpler transition to using subsystems in the future
     */
    public string function buildURL( string action = '.', string path = variables.magicBaseURL, any queryString = '' ) {
        if ( action == '.' ) {
            action = getSubsystemSectionAndItem();
        } else if ( left( action, 2 ) == '.?' ) {
            action = replace( action, '.', getSubsystemSectionAndItem() );
        }
        var pathData = resolveBaseURL( action, path );
        path = pathData.path;
        var omitIndex = pathData.omitIndex;
        queryString = normalizeQueryString( queryString );
        var q = 0;
        var a = 0;
        if ( queryString == '' ) {
            // extract query string from action section:
            q = find( '?', action );
            a = find( '##', action );
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
        var cosmeticAction = getSubsystemSectionAndItem( action );
        var isHomeAction = cosmeticAction == getSubsystemSectionAndItem( variables.framework.home );
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

        if ( getSubsystem( cosmeticAction ) == variables.framework.defaultSubsystem ) {
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
            throw( type='FW1.controllerExecutionStarted', message="Controller '#action#' may not be added at this point.",
                   detail='The controller execution phase has already started. Controllers may not be added by other controller methods.' );
        }

        tuple.controller = getController( section = section, subsystem = subsystem );
        tuple.key = subsystem & variables.framework.subsystemDelimiter & section;
        tuple.subsystem = subsystem;
        tuple.section = section;
        tuple.item = item;

        if ( structKeyExists( tuple, 'controller' ) && !isNull( tuple.controller ) && isObject( tuple.controller ) ) {
            internalFrameworkTrace( 'queuing controller', subsystem, section, item );
            arrayAppend( request._fw1.controllers, tuple );
        }
    }

    /*
     * can be overridden to customize how views and layouts are actually
     * rendered; should return null if the default rendering should apply
     */
    public any function customTemplateEngine( string type, string path, struct scope ) {
        return;
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
     * call this to disable rendering of the layout
     */
    public void function disableLayout() {
        request.layout = false;
    }

    /*
     * call this to (re-)enable tracing
     */
    public void function enableFrameworkTrace() {
        request._fw1.doTrace = true;
    }

    /*
     * call this to (re-)enable rendering of the layout
     */
    public void function enableLayout() {
        request.layout = true;
    }

    public void function frameworkTrace( string message ) {
        if ( request._fw1.doTrace ) {
            try {
                if ( sessionHas( '_fw1_trace' ) ) {
                    request._fw1.trace = sessionRead( '_fw1_trace' );
                    sessionDelete( '_fw1_trace' );
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
     *  returns whatever the framework has been told is a bean factory
     *  this will return a subsystem-specific bean factory if one
     *  exists for the current request's subsystem (or for the specified subsystem
     *  if passed in)
     */
    public any function getBeanFactory( string subsystem = '' ) {
        if ( len( subsystem ) > 0 ) {
            if ( hasSubsystemBeanFactory( subsystem ) ) {
                return getSubsystemBeanFactory( subsystem );
            }
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
        return getFw1App().factory;
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
            throw( type='FW1.subsystemNotSpecified', message='No subsystem specified and no default configured.',
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
     * convenience function to look up environment variables
     * expected to be used without your own getEnvironment()
     * function along with / instead of getHostname()
     */
    public string function getEnvVar( string name ) {
        return createObject( "java", "java.lang.System" ).getenv( name );
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
     * if the subsystem is empty, do _not_ include the delimiter - compare this behavior
     * with getSubsystemSectionAndItem() below
     */
    public string function getFullyQualifiedAction( string action = request.action ) {
        var requested = getSubsystem( action );
        if ( len( requested ) ) {
            // request specifies non-empty subsystem, use it as-is:
            return requested & variables.framework.subsystemDelimiter & getSectionAndItem( action );
        } else {
            var current = structKeyExists( request, 'action' ) ? getSubsystem( request.action ) : '';
            if ( len( current ) ) {
                // request has no subsystem but we're in one, special case
                if ( actionSpecifiesSubsystem( action ) ) {
                    // request had explicit empty subsystem so it means top-level app
                    return variables.framework.subsystemDelimiter & getSectionAndItem( action );
                } else {
                    // request was meant to be relative to current subsystem
                    return current & variables.framework.subsystemDelimiter & getSectionAndItem( action );
                }
            } else {
                // neither appears to have subsystem, just use section and item
                return getSectionAndItem( action );
            }
        }
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
     * return this request's CGI method
     */
    public string function getCGIRequestMethod() {
        return request._fw1.cgiRequestMethod;
    }

    /*
     * return the current route (if any)
     * this is the raw, matched route that we mapped
     */
    public string function getRoute() {
        return structKeyExists( request._fw1, 'route' ) ? request._fw1.route : '';
    }

    /*
     * return the part of the pathinfo that was used as the route
     * prefixed by the HTTP method
     */
    public string function getRoutePath() {
        return '$' & request._fw1.cgiRequestMethod & request._fw1.currentRoute;
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
        if ( actionSpecifiesSubsystem( action ) ) {
            sectionAndItem = segmentLast( action, variables.framework.subsystemDelimiter );
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
     * return the subsystem part of the action
     */
    public string function getSubsystem( string action = request.action ) {
        if ( actionSpecifiesSubsystem( action ) ) {
            return segmentFirst( action, variables.framework.subsystemDelimiter );
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
     * returns the bean factory set via setSubsystemBeanFactory
     * same effect as getBeanFactory when not using subsystems
     */
    public any function getSubsystemBeanFactory( string subsystem ) {

        setupSubsystemWrapper( subsystem );

        return getFw1App().subsystemFactories[ subsystem ];

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
     * return the subsytem and section part of the action
     */
    public string function getSubsystemSection( string action = request.action ) {
        return listFirst( getSubsystemSectionAndItem( action ), '.' );
    }

    /*
     * return an action with all applicable parts (subsystem, section, and item) specified
     * using defaults from the configuration or request where appropriate
     * differs from getFullyQualifiedAction() in that it will _always_ contain the
     * subsystem delimiter, even when the subsystem is blank
     */
    public string function getSubsystemSectionAndItem( string action = request.action ) {
        if ( actionSpecifiesSubsystem( action ) ) {
            return getSubsystem( action ) & variables.framework.subsystemDelimiter & getSectionAndItem( action );
        } else {
            var current = structKeyExists( request, 'action' ) ? getSubsystem( request.action ) : '';
            if ( len( current ) ) {
                return current & variables.framework.subsystemDelimiter & getSectionAndItem( action );
            } else {
                return variables.framework.subsystemDelimiter & getSectionAndItem( action );
            }
        }
    }

    /*
     * returns true iff a call to getBeanFactory() will successfully return a bean factory
     * previously set via setBeanFactory or setSubsystemBeanFactory
     */
    public boolean function hasBeanFactory() {

        if ( hasDefaultBeanFactory() ) {
            return true;
        }

        if ( structKeyExists( request, 'subsystem' ) ) {
            return hasSubsystemBeanFactory( request.subsystem );
        }

        if ( len( variables.framework.defaultSubsystem ) > 0 ) {
            return hasSubsystemBeanFactory( variables.framework.defaultSubsystem );
        }

        return false;

    }

    /*
     * returns true iff the framework has been told about a bean factory via setBeanFactory
     */
    public boolean function hasDefaultBeanFactory() {
        return structKeyExists( getFw1App(), 'factory' );
    }

    /*
     * returns true if a subsystem specific bean factory has been set
     */
    public boolean function hasSubsystemBeanFactory( string subsystem ) {

        if ( !len( subsystem ) ) return false;
        setupSubsystemWrapper( subsystem );

        return structKeyExists( getFw1App().subsystemFactories, subsystem );

    }

    /*
     * returns true if the specified action matches the currently
     * executing action (after both have been expanded)
     */
    public boolean function isCurrentAction( string action ) {
        return getSubsystemSectionAndItem( action ) ==
            getSubsystemSectionAndItem();
    }

    /*
     * returns true if this request has a valid reload URL parameter
     */
    public boolean function isFrameworkReloadRequest() {
        setupRequestDefaults();
        return ( isDefined( 'URL' ) &&
                 structKeyExists( URL, variables.framework.reload ) &&
                 URL[ variables.framework.reload ] == variables.framework.password ) ||
            variables.framework.reloadApplicationOnEveryRequest;
    }

    /*
     * you can override this to dynamically tell FW/1 to not handle
     * specific requests - by default it uses the unhandledExtensions
     * and unhandledPaths configuration items so if you want that as
     * well as your own custom paths, write a test like:
     * return super.isUnhandledRequest( targetPath ) || myCustomChecks();
     */
    public boolean function isUnhandledRequest( string targetPath ) {
        // allow configured extensions and paths to pass through to
        // the requested template.
        // NOTE: for unhandledPaths, we make the list into an escaped
        // regular expression so we match on subdirectories, meaning
        // /myexcludepath will match '/myexcludepath' and all subdirectories
        return listFindNoCase( variables.framework.unhandledExtensions,
                               listLast( targetPath, '.' ) ) ||
            REFindNoCase( '^(' & variables.framework.unhandledPathRegex & ')',
                          targetPath );
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
     * Exotic utility function to create proxies for FW/1 methods that can be
     * called from Java: can be used with external rendering engines, for example
     * NOTE: requires Java 8 for Function<> interface!
     */
    public struct function makeMethodProxies( array methodNames ) {
        var proxies = { };
        for ( var method in methodNames ) {
            proxies[ method ] = createDynamicProxy(
                new framework.methodProxy( this, method ),
                [ "java.util.function.Function" ]
            );
        }
        return proxies;
    }

    /*
     * it is better to set up your application configuration in
     * your setupApplication() method since that is called on a
     * framework reload
     * if you do override onApplicationStart(), you must call
     * super.onApplicationStart() first
     */
    public any function onApplicationStart() {
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
            structDelete( request._fw1, 'controllerExecutionStarted' );
            structDelete( request._fw1, 'overrideLayoutAction' );
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
            var key = 'error';
            var defaultAction = 'main.error';
            try {
                if ( exception.type == 'fw1.viewnotfound' && structKeyExists( variables.framework, 'missingview' ) ) {
                    key = 'missingview';
                    // shouldn't be needed -- key will be present in framework config
                    defaultAction = 'main.missingview';
                }
            } catch ( any e ) {
                // leave it as exception
            }
            if ( structKeyExists( variables, 'framework' ) && structKeyExists( variables.framework, key ) ) {
                request.action = variables.framework[ key ];
            } else {
                // this is an edge case so we don't bother with subsystems etc
                // (because if part of the framework defaults are not present,
                // we'd have to do a lot of conditional logic here!)
                request.action = defaultAction;
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
    public any function onMissingView( struct rc ) {
        // unable to find a matching view - fail with a nice exception
        viewNotFound();
        // if we got here, we would return the string or struct to be rendered
        // but viewNotFound() throws an exception...
        // for example, return view( 'main/missing' );
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
     * This can be overridden if you want to take some actions when the
     * framework is about to be reloaded, prior to starting the next
     * application cycle. This will be called when an explicit reload is
     * performed, or on each request if reloadApplicationOnEveryRequest is
     * set true. You could use it to perform housekeeping of services, prior
     * to them all being recreated in a new bean factory, for example.
     */
    public void function onReload() {
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
        if ( variables.framework.preflightOptions &&
             request._fw1.cgiRequestMethod == "OPTIONS" &&
             structCount( request._fw1.routeMethodsMatched ) ) {
            // OPTIONS support enabled and at least one possible match
            // bypass all normal controllers and render headers and data:
            var resp = getPageContext().getResponse();
            resp.setHeader( "Access-Control-Allow-Origin", variables.framework.optionsAccessControl.origin );
            resp.setHeader( "Access-Control-Allow-Methods", "OPTIONS," & uCase( structKeyList( request._fw1.routeMethodsMatched ) ) );
            resp.setHeader( "Access-Control-Allow-Headers", variables.framework.optionsAccessControl.headers );
            resp.setHeader( "Access-Control-Allow-Credentials", variables.framework.optionsAccessControl.credentials ? "true" : "false" );
            resp.setHeader( "Access-Control-Max-Age", "#variables.framework.optionsAccessControl.maxAge#" );
            renderData( "text", "" );
        } else {
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
                    doController( tuple, tuple.item, 'item' );
                    if ( structKeyExists( request._fw1, 'abortController' ) ) abortController();
                }
                n = arrayLen( request._fw1.controllers );
                for ( i = n; i >= 1; i = i - 1 ) {
                    tuple = request._fw1.controllers[ i ];
                    // run after once per controller (in reverse order):
                    if ( once[ tuple.key ] eq i ) {
                        doController( tuple, 'after', 'after' );
                        if ( structKeyExists( request._fw1, 'abortController' ) ) abortController();
                    }
                }
            } catch ( FW1.AbortControllerException e ) {
                // do "nothing" since this is a control flow exception
            }
        }

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
        if ( isSimpleValue( out ) ) {
            writeOutput( out );
        } else {
            if ( structKeyExists( out, 'contentType' ) ) {
                var resp = getPageContext().getResponse();
                resp.setContentType( out.contentType );
            }
            if ( structKeyExists( out, 'writer' ) ) {
                out.writer( out.output );
            } else {
                writeOutput( out.output );
            }
        }
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
        setupRequestDefaults();

        if ( !isFrameworkInitialized() ) {
            setupApplicationWrapper();
        } else if ( isFrameworkReloadRequest() ) {
            onReload();
            setupApplicationWrapper();
        } else {
            request._fw1.theApp = getFw1App();
        }

        restoreFlashContext();
        // ensure flash context cannot override request action:
        request.context[variables.framework.action] = request.action;

        if ( isUnhandledRequest( targetPath ) ) {
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

    public struct function processRoutes( string path, array routes, string httpMethod = request._fw1.cgiRequestMethod ) {
        for ( var routePack in routes ) {
            for ( var route in routePack ) {
                if ( route == 'hint' ) continue;
                if ( route == '$RESOURCES' ) {
                    var routeMatch = processRoutes( path, getResourceRoutes( routePack[ route ] ), httpMethod );
                } else {
                    var routeMatch = processRouteMatch( route, routePack[ route ], path, httpMethod );
                }
                if ( routeMatch.matched ) return routeMatch;
            }
        }
        return { matched = false };
    }

    // call from your controller to redirect to a clean URL based on an action, pushing data to flash scope if necessary:
    public void function redirect(
        string action, string preserve = 'none', string append = 'none', string path = variables.magicBaseURL,
        any queryString = '', string statusCode = '302', string header = ''
    ) {
        if ( path == variables.magicBaseURL ) path = getBaseURL();
        var preserveKey = '';
        if ( preserve != 'none' ) {
            preserveKey = saveFlashContext( preserve );
        }
        queryString = normalizeQueryString( queryString );
        var baseQueryString = '';
        if ( append != 'none' ) {
            if ( append == 'all' ) {
                for ( var key in request.context ) {
                    if ( isSimpleValue( request.context[ key ] ) ) {
                        baseQueryString = listAppend( baseQueryString, key & '=' & encodeForURL( request.context[ key ] ), '&' );
                    }
                }
            } else {
                var keys = listToArray( append );
                for ( var key in keys ) {
                    if ( structKeyExists( request.context, key ) && isSimpleValue( request.context[ key ] ) ) {
                        baseQueryString = listAppend( baseQueryString, key & '=' & encodeForURL( request.context[ key ] ), '&' );
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
                sessionWrite( '_fw1_trace', request._fw1.trace );
            } catch ( any _ ) {
                // ignore exception if session is not enabled
            }
        }
        if ( len( header ) ) {
            // per #338 support custom header-based redirect
            getPageContext().getResponse().setStatus( statusCode );
            getPageContext().getResponse().setHeader( header, targetURL );
            abortController();
        } else {
            location( targetURL, false, statusCode );
        }
    }

    // append and querystring are not supported here: you are providing the URI so
    // you are responsible for all of its contents
    public void function redirectCustomURL( string uri, string preserve = 'none', string statusCode = '302', string header = '' ) {
        var preserveKey = '';
        if ( preserve != 'none' ) {
            preserveKey = saveFlashContext( preserve );
        }
        var targetURL = buildCustomURL( uri );
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
                sessionWrite( '_fw1_trace', request._fw1.trace );
            } catch ( any _ ) {
                // ignore exception if session is not enabled
            }
        }
        if ( len( header ) ) {
            // per #338 support custom header-based redirect
            getPageContext().getResponse().setStatus( statusCode );
            getPageContext().getResponse().setHeader( header, targetURL );
            abortController();
        } else {
            location( targetURL, false, statusCode );
        }
    }

    // call this to render data rather than a view and layouts
    // arguments are deprecated in favor of build syntax as of 4.0
    public any function renderData( string type = '', any data = '', numeric statusCode = 200, string jsonpCallback = "" ) {
        if ( statusCode != 200 ) deprecated( false, "Use the .statusCode() builder syntax instead of the inline argument." );
        if ( len( jsonpCallback ) ) deprecated( false, "Use the .jsonpCallback() builder syntax instead of the inline argument." );
        request._fw1.renderData = {
            type = type,
            data = data,
            statusCode = statusCode,
            statusText = '',
            jsonpCallback = jsonpCallback
        };
        // return a builder to support nicer rendering syntax
        return renderer();
    }

    public any function renderer() {
        var builder = { };
        structAppend( builder, {
            // allow type and data to be overridden just for completeness
            type : function( v ) {
                if ( !structKeyExists( request._fw1, 'renderData' ) ) request._fw1.renderData = { };
                request._fw1.renderData.type = v;
                return builder;
            },
            data : function( v ) {
                if ( !structKeyExists( request._fw1, 'renderData' ) ) request._fw1.renderData = { };
                request._fw1.renderData.data = v;
                return builder;
            },
            header : function( h, v ) {
                if ( !structKeyExists( request._fw1, 'renderData' ) ) request._fw1.renderData = { };
                if ( !structKeyExists( request._fw1.renderData, 'headers' ) ) {
                    request._fw1.renderData.headers = [ ];
                }
                arrayAppend( request._fw1.renderData.headers, { name = h, value = v } );
                return builder;
            },
            statusCode : function( v ) {
                if ( !structKeyExists( request._fw1, 'renderData' ) ) request._fw1.renderData = { };
                request._fw1.renderData.statusCode = v;
                return builder;
            },
            statusText : function( v ) {
                if ( !structKeyExists( request._fw1, 'renderData' ) ) request._fw1.renderData = { };
                request._fw1.renderData.statusText = v;
                return builder;
            },
            jsonpCallback : function( v ) {
                if ( !structKeyExists( request._fw1, 'renderData' ) ) request._fw1.renderData = { };
                request._fw1.renderData.jsonpCallback = v;
                return builder;
            }
        } );
        return builder;
    }

    public void function sessionDefault( string keyname, any defaultValue ) {
        param name="session['#keyname#']" default="#defaultValue#";
    }

    public void function sessionDelete( string keyname ) {
        structDelete( session, keyname );
    }

    public boolean function sessionHas( string keyname ) {
        return structKeyExists( session, keyname );
    }

    public void function sessionLock( required function callback ) {
        lock scope="session" type="exclusive" timeout="30" {
            callback();
        }
    }

    public any function sessionRead( string keyname ) {
        return session[ keyname ];
    }

    public void function sessionWrite( string keyname, any keyvalue ) {
        session[ keyname ] = keyvalue;
    }

    /*
     * call this from your setupApplication() method to tell the framework
     * about your bean factory - only assumption is that it supports:
     * - containsBean(name) - returns true if factory contains that named bean, else false
     * - getBean(name) - returns the named bean
     */
    public void function setBeanFactory( any beanFactory ) {
        if ( isObject( beanFactory ) ) {
            if ( structKeyExists( getFw1App(), "factory" ) ) {
                if ( variables.framework.diOverrideAllowed ) {
                    // we still log a warning because this is strange behavior
                    var out = createObject( "java", "java.lang.System" ).out;
                    out.println( "FW/1: WARNING: setBeanFactory() called more than once - use diEngine = 'none'?" );
                    internalFrameworkTrace( message = "FW/1: WARNING: setBeanFactory() called more than once - use diEngine = 'none'?", traceType = 'WARNING' );
                } else {
                    throw( type = "FW1.Warning",
                           message = "setBeanFactory() called more than once - use diEngine = 'none'?",
                           detail = "Either set diEngine to 'none' or let FW/1 manage your bean factory for you." );
                }
            }
            getFw1App().factory = beanFactory;
        } else {
            structDelete( getFw1App(), "factory" );
        }
        // to address #276 flush controller cache when bean factory is reset:
        getFw1App().cache.controllers = { };

    }

    /*
     * use this to override the default layout
     */
    public void function setLayout( string action, boolean suppressOtherLayouts = false ) {
        request._fw1.overrideLayoutAction = validateAction( getFullyQualifiedAction( action ) );
        request._fw1.suppressOtherLayouts = suppressOtherLayouts;
    }

    /*
     * call this from your setupSubsystem() method to tell the framework
     * about your subsystem-specific bean factory - only assumption is that it supports:
     * - containsBean(name) - returns true if factory contains that named bean, else false
     * - getBean(name) - returns the named bean
     */
    public void function setSubsystemBeanFactory( string subsystem, any factory ) {

        ensureNewFrameworkStructsExist();
        getFw1App().subsystemFactories[ subsystem ] = factory;

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
     * and handle it yourself
     */
    public void function setupTraceRender( string output = 'html' ) { }

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
        request._fw1.overrideViewAction = validateAction( getFullyQualifiedAction( action ) );
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
    public any function view( string path, struct args = { },
                              any missingView = { } ) {
        var viewPath = parseViewOrLayoutPath( path, 'view' );
        if ( cachedFileExists( viewPath ) ) {
            internalFrameworkTrace( 'view( #path# ) called - rendering #viewPath#' );
            return internalView( viewPath, args );
        } else if ( isSimpleValue( missingView ) ) {
            return missingView;
        } else if ( structKeyExists(request._fw1, 'omvInProgress') ) {
            internalFrameworkTrace( 'view( #path# ) called - viewNotFound() called' );
            request.missingView = path;
            viewNotFound();
        } else {
            request._fw1.omvInProgress = true;
            internalFrameworkTrace( 'view( #path# ) called - onMissingView() called' );
            request.missingView = path;
            return onMissingView( request.context );
        }
    }

    // EXPERIMENTAL COLDBOX MODULE SUPPORT

    /*
     * in Application.cfc, call as follows:
     *   this.mappings = moduleMappings( "qb, supermod" );
     *   this.mappings = moduleMappings( [ "mod1", "mod2"], "modules" );
     */
    public struct function moduleMappings( any modules, string modulePath = "modules" ) {
    		if ( isSimpleValue( modules ) ) modules = listToArray( modules );
    		var cleanModules = [ ];
    		var mappings = { };
    		for ( var m in modules ) {
    			m = trim( m );
    			arrayAppend( cleanModules, m );
    			mappings[ "/" & m ] = expandPath( "/" & modulePath & "/" & m );
    		}
    		variables._fw1_coldbox_modulePath = modulePath;
    		variables._fw1_coldbox_modules = cleanModules;
    		return mappings;
  	}

    /*
     * call this in setupApplication() to load the modules for which
     * you set up moduleMappings() using the function above -- the
     * frameworkPath argument can override the default location for FW/1
     */
  	public void function installModules( string frameworkPath = "framework" ) {
    		var bf = new "#frameworkPath#.WireBoxAdapter"();
    		getBeanFactory().setParent( bf );
    		var builder = bf.getBuilder();
    		var nullObject = new "#frameworkPath#.nullObject"();
    		var cbdsl = { };
    		cbdsl.init = function() { return cbdsl; };
    		cbdsl.process = function() { return nullObject; };
    		builder.vars = __vars;
    		builder.vars().instance.ColdBoxDSL = cbdsl;
    		for ( var module in variables._fw1_coldbox_modules ) {
      			var cfg = new "#variables._fw1_coldbox_modulePath#.#module#.ModuleConfig"();
      			cfg.vars = __vars;
      			cfg.vars().binder = bf.getBinder();
            cfg.vars().controller = {
                getWireBox : function() { return bf; }
            };
      			cfg.configure();
      			if ( structKeyExists( variables.framework, "modules" ) &&
      	  			 structKeyExists( variables.framework.modules, module ) ) {
			         structAppend( cfg.vars().settings, variables.framework.modules[ module ] );
      			}
      			cfg.onLoad();
    		}
  	}
    // helper to allow mixins:
  	private struct function __vars() { return variables; }

    // THE FOLLOWING METHODS SHOULD ALL BE CONSIDERED PRIVATE / UNCALLABLE

    private void function autowire( any cfc, any beanFactory ) {
        var setters = findImplicitAndExplicitSetters( cfc );
        for ( var property in setters ) {
            if ( beanFactory.containsBean( property ) ) {
                var args = { };
                args[ property ] = beanFactory.getBean( property );
                invoke( cfc, "set#property#", args );
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
        var cascadeLayouts = true; // default can be overridden via setLayout() second argument

        // has layout been overridden?
        if ( structKeyExists( request._fw1, 'overrideLayoutAction' ) ) {
            subsystem = getSubsystem( request._fw1.overrideLayoutAction );
            section = getSection( request._fw1.overrideLayoutAction );
            item = getItem( request._fw1.overrideLayoutAction );
            structDelete( request._fw1, 'overrideLayoutAction' );
            if ( structKeyExists( request._fw1, 'suppressOtherLayouts' ) ) {
                cascadeLayouts = !request._fw1.suppressOtherLayouts;
                structDelete( request._fw1, 'suppressOtherLayouts' );
            }
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
        if ( cascadeLayouts ) {
            // look for section-specific layout:
            testLayout = parseViewOrLayoutPath( subsystem & variables.framework.subsystemDelimiter & section, 'layout' );
            if ( cachedFileExists( testLayout ) ) {
                internalFrameworkTrace( 'found section-specific layout #testLayout#', subsystem, section, item );
                arrayAppend( request._fw1.layouts, testLayout );
            }
            // look for subsystem-specific layout (site-wide layout if not using subsystems):
            if ( request.section != 'default' ) {
                testLayout = parseViewOrLayoutPath( subsystem & variables.framework.subsystemDelimiter & 'default', 'layout' );
                if ( cachedFileExists( testLayout ) ) {
                    internalFrameworkTrace( 'found default layout #testLayout#', subsystem, section, item );
                    arrayAppend( request._fw1.layouts, testLayout );
                }
            }
            // look for site-wide layout (only applicable if using subsystems)
            if ( usingSubsystems() ) {
                if ( siteWideLayoutBase != subsystembase ) {
                    testLayout = parseViewOrLayoutPath( variables.framework.siteWideLayoutSubsystem &
                                                        variables.framework.subsystemDelimiter & 'default', 'layout' );
                    if ( cachedFileExists( testLayout ) ) {
                        internalFrameworkTrace( 'found #variables.framework.siteWideLayoutSubsystem# layout #testLayout#',
                                                subsystem, section, item );
                        arrayAppend( request._fw1.layouts, testLayout );
                    }
                }
            } else if ( len( subsystem ) ) {
                testLayout = parseViewOrLayoutPath( variables.framework.subsystemDelimiter & 'default', 'layout' );
                if ( cachedFileExists( testLayout ) ) {
                    internalFrameworkTrace( 'found application layout #testLayout#',
                                            subsystem, section, item );
                    arrayAppend( request._fw1.layouts, testLayout );
                }
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
        var cache = getFw1App().cache;
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
            internalFrameworkTrace( message = "FW/1: DEPRECATED: " & message, traceType = 'DEPRECATED' );
        }
    }

    private void function doController( struct tuple, string method, string lifecycle ) {
        var cfc = tuple.controller;
        if ( structKeyExists( cfc, method ) ) {
            try {
                internalFrameworkTrace( 'calling #lifecycle# controller', tuple.subsystem, tuple.section, method );
                invoke( cfc, method, { rc : request.context, headers : request._fw1.headers } );
            } catch ( any e ) {
                setCfcMethodFailureInfo( cfc, method );
                rethrow;
            }
        } else if ( structKeyExists( cfc, 'onMissingMethod' ) ) {
            try {
                internalFrameworkTrace( 'calling #lifecycle# controller (via onMissingMethod)', tuple.subsystem, tuple.section, method );
                invoke( cfc, method, { rc : request.context, method : lifecycle, headers : request._fw1.headers } );
            } catch ( any e ) {
                setCfcMethodFailureInfo( cfc, method );
                rethrow;
            }
        } else {
            internalFrameworkTrace( 'no #lifecycle# controller to call', tuple.subsystem, tuple.section, method );
        }
    }

    private void function dumpException( any exception ) {
        writeDump( var = exception, label = 'Exception - click to expand', expand = false );
    }

    private void function ensureNewFrameworkStructsExist() {

        var framework = getFw1App();

        if ( !structKeyExists( framework, 'subsystemFactories' ) ) {
            framework.subsystemFactories = { };
        }

        if ( !structKeyExists( framework, 'subsystems' ) ) {
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
            writeOutput( '<h#h#>' & ( indirect ? 'Original exception ' : 'Exception' ) & ' in #encodeForHTML(event)#</h#h#>' );
            if ( structKeyExists( request, 'failedAction' ) ) {
                writeOutput( '<p>The action #encodeForHtml(request.failedAction)# failed.</p>' );
            }
            writeOutput( '<h#1+h#>#encodeForHtml(exception.message)#</h#1+h#>' );
        }

        writeOutput( '<p>#encodeForHtml(exception.detail)# (#encodeForHtml(exception.type)#)</p>' );
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
        if ( !structKeyExists( cfc, '__fw1_version' ) ) {
            // gather up explicit setters as well - except for FW/1 / Application.cfc
            for ( var member in cfc ) {
                var method = cfc[ member ];
                var n = len( member );
                if ( isCustomFunction( method ) && left( member, 3 ) == 'set' && n > 3 ) {
                    var property = right( member, n - 3 );
                    setters[ property ] = 'explicit';
                }
            }
        }
        return setters;
    }

    private void function frameworkTraceRender() {
        // do not output trace information if we are rendering data as opposed
        // to rendering HTML views - see #226 and #232
        if ( request._fw1.doTrace &&
             arrayLen( request._fw1.trace ) ) {
            setupTraceRender( structKeyExists( request._fw1, 'renderData' ) ? 'data' : 'html' );
        }
        // re-test to allow for setupTraceRender() handling / disabling tracing
        if ( request._fw1.doTrace &&
             arrayLen( request._fw1.trace ) &&
             !structKeyExists( request._fw1, 'renderData' ) ) {
            var startTime = request._fw1.trace[1].tick;
            var font = 'font-family: verdana, helvetica;';
            writeOutput( '<hr /><div id="fw1_trace" style="background: ##ccdddd; color: black; border: 1px solid; border-color: black; padding: 5px; #font#">' );
            writeOutput( '<div style="#font# font-weight: bold; font-size: large; float: left;">Framework Lifecycle Trace</div><div style="clear: both;"></div>' );
            var table = '<table style="border: 1px solid; border-color: black; color: black; #font#" width="100%">' &
                '<tr><th style="text-align:right;" width="5%">time</th><th style="text-align:right;" width="5%">delta</th>' &
                '<th style="text-align:center;">type</th><th width="10%">action</th><th>message</th></tr>';
            writeOutput( table );
            var colors = [ '##ccd4dd', '##ccddcc' ];
            var row = 0;
            var n = arrayLen( request._fw1.trace );
            var lastDuration = 0;
            for ( var i = 1; i <= n; ++i ) {
                var trace = request._fw1.trace[i];
                var nextTraceTick = i + 1 <= n ? request._fw1.trace[i+1].tick : trace.tick;
                var color = '##000';
                var traceType = structKeyExists( trace, 't' ) ? trace.t : 'INFO';
                if ( trace.msg.startsWith( 'no ' ) ) color = '##cc8888';
                else if ( trace.msg.startsWith( 'onError( ' ) || traceType == 'ERROR' ) color = '##cc0000';
                else if ( traceType == 'WARNING' ) color = '##d44b0f';
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
                writeOutput( '</td>' );
                if ( !structKeyExists( trace, 't' ) || trace.t == 'INFO' ) {
                    writeOutput( '<td>&nbsp;</td>' );
                } else {
                    writeOutput( '<td style="text-align: center; color: #color#">#ucase(trace.t)#</td>' );
                }
                writeOutput( '<td style="border: 0; color: black; #font# font-size: small;padding-left: 5px;" width="10%">#action#</td>' );
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
            writeOutput( '</table></div>' );
        }
    }

    private any function getCachedController( string subsystem, string section ) {

        setupSubsystemWrapper( subsystem );
        var cache = getFw1App().cache;
        var cfc = 0;
        var subsystemDir = getSubsystemDirPrefix( subsystem );
        var subsystemDot = replace( subsystemDir, '/', '.', 'all' );
        var subsystemUnderscore = replace( subsystemDir, '/', '_', 'all' );
        var componentKey = subsystemUnderscore & section;
        var beanName = section & variables.controllerFolder;
        var controllersSlash = variables.framework.controllersFolder & '/';
        var controllersDot = variables.framework.controllersFolder & '.';
        // per #310 we no longer cache the Application controller since it is new on each request
        if ( section == variables.magicApplicationController ) {
            if ( hasDefaultBeanFactory() ) {
                autowire( this, getDefaultBeanFactory() );
            }
            return this;
        }
        if ( !structKeyExists( cache.controllers, componentKey ) ) {
            lock name="fw1_#application.applicationName#_#variables.framework.applicationKey#_#componentKey#" type="exclusive" timeout="30" {
                if ( !structKeyExists( cache.controllers, componentKey ) ) {
                    if ( hasSubsystemBeanFactory( subsystem ) && getSubsystemBeanFactory( subsystem ).containsBean( beanName ) ) {
                        cfc = getSubsystemBeanFactory( subsystem ).getBean( beanName );
                    } else if ( !usingSubsystems() && hasDefaultBeanFactory() && getDefaultBeanFactory().containsBean( beanName ) ) {
                        cfc = getDefaultBeanFactory().getBean( beanName );
                    } else {
                        if ( cachedFileExists( cfcFilePath( request.cfcbase ) & subsystemDir & controllersSlash & section & '.cfc' ) ) {
                            // we call createObject() rather than new so we can control initialization:
                            if ( request.cfcbase == '' ) {
                                cfc = createObject( 'component', subsystemDot & controllersDot & section );
                            } else {
                                cfc = createObject( 'component', request.cfcbase & '.' & subsystemDot & controllersDot & section );
                            }
                            if ( structKeyExists( cfc, 'init' ) ) {
                                cfc.init( this );
                            }
                        }
                        if ( isObject( cfc ) && ( hasDefaultBeanFactory() || hasSubsystemBeanFactory( subsystem ) ) ) {
                            autowire( cfc, getBeanFactory( subsystem ) );
                        }
                    }
                    if ( isObject( cfc ) ) {
                        injectFramework( cfc );
                        cache.controllers[ componentKey ] = cfc;
                    }
                }
            }
        }

        if ( structKeyExists( cache.controllers, componentKey ) ) {
            return cache.controllers[ componentKey ];
        }
        // else "return null" effectively
    }

    private any function getController( string section, string subsystem = getDefaultSubsystem() ) {
        var _controller_fw1 = getCachedController( subsystem, section );
        if ( !isNull( _controller_fw1 ) ) {
            return _controller_fw1;
        }
    }

    private struct function getFw1App() {
        if ( structKeyExists( request._fw1, 'theApp' ) ) {
            return request._fw1.theApp;
        } else {
            return application[variables.framework.applicationKey];
        }
    }

    private string function getNextPreserveKeyAndPurgeOld() {
        var nextPreserveKey = '';
        var oldKeyToPurge = '';
        try {
            sessionLock(function() localmode = "classic" {
                if ( variables.framework.maxNumContextsPreserved > 1 ) {
                    sessionDefault( '__fw1NextPreserveKey', 1 );
                    nextPreserveKey = sessionRead( '__fw1NextPreserveKey' );
                    sessionWrite( '__fw1NextPreserveKey', nextPreserveKey + 1 );
                    oldKeyToPurge = nextPreserveKey - variables.framework.maxNumContextsPreserved;
                } else {
                    nextPreserveKey = '';
                    sessionWrite( '__fw1PreserveKey', nextPreserveKey );
                    oldKeyToPurge = '';
                }
            });
            var key = getPreserveKeySessionKey( oldKeyToPurge );
            if ( sessionHas( key ) ) {
                sessionDelete( key );
            }
        } catch ( any e ) {
            // ignore - assume session scope is disabled
        }
        return nextPreserveKey;
    }

    private string function getPreserveKeySessionKey( string preserveKey ) {
        return '__fw1' & preserveKey;
    }

    private any function getProperty( struct cfc, string property ) {
        if ( structKeyExists( cfc, 'get#property#' ) ) return invoke( cfc, "get#property#" );
    }

    private string function getSubsystemDirPrefix( string subsystem ) {

        if ( subsystem eq '' ) {
            return '';
        }
        if ( usingSubsystems() ) {
            return subsystem & '/';
        } else {
            return variables.framework.subsystemsFolder & '/' & subsystem & '/';
        }
    }

    private void function injectFramework( any cfc ) {
        var args = { };
        if ( structKeyExists( cfc, 'setFramework' ) || structKeyExists( cfc, 'onMissingMethod' ) ) {
            args.framework = this;
            // allow alternative spellings
            args.fw = this;
            args.fw1 = this;
            cfc.setFramework( argumentCollection = args );
        }
    }

    private void function internalFrameworkTrace( string message, string subsystem = '', string section = '', string item = '', string traceType = 'INFO' ) {
        if ( request._fw1.doTrace ) {
            try {
                if ( sessionHas( '_fw1_trace' ) ) {
                    request._fw1.trace = sessionRead( '_fw1_trace' );
                    sessionDelete( '_fw1_trace' );
                }
            } catch ( any _ ) {
                // ignore if session is not enabled
            }
            arrayAppend( request._fw1.trace, { tick = getTickCount(), msg = message, sub = subsystem, s = section, i = item, t = traceType } );
        }
    }

    private string function internalLayout( string layoutPath, string body ) {
        var rc = request.context;
        var $ = { };
        // integration point with Mura:
        if ( structKeyExists( rc, '$' ) ) {
            $ = rc.$;
        }
        local.body = body;
        var response = customTemplateEngine( 'layout', layoutPath, local );
        if ( isNull( response ) ) {
            response = '';
            savecontent variable="response" {
                include '#layoutPath#';
            }
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
        var response = customTemplateEngine( 'view', viewPath, local );
        if ( isNull( response ) ) {
            response = '';
            savecontent variable="response" {
                include '#viewPath#';
            }
        }
        return response;
    }

    private boolean function isFrameworkInitialized() {
        return structKeyExists( variables, 'framework' ) &&
            ( structKeyExists( request._fw1, 'theApp' ) ||
              structKeyExists( application, variables.framework.applicationKey ) );
    }

    private boolean function isSubsystemInitialized( string subsystem ) {

        ensureNewFrameworkStructsExist();

        return structKeyExists( getFw1App().subsystems, subsystem );

    }

    // like listFirst() and listLast() but they actually work with empty segments
    private string function segmentFirst( string segments, string delimiter ) {
        var where = find( delimiter, segments );
        if ( where ) {
            if ( where == 1 ) {
                return '';
            } else {
                return left( segments, where - 1 );
            }
        }
        return '';
    }

    private string function normalizeQueryString( any queryString ) {
        // if queryString is a struct, massage it into a string
        if ( isStruct( queryString ) && structCount( queryString ) ) {
            var q = '';
            for( var key in queryString ) {
                if ( isSimpleValue( queryString[key] ) ) {
                    q = listAppend(q, encodeForURL( key ) & '=' & encodeForURL( queryString[ key ] ), '&');
                }
            }
            queryString = q;
        }
        else if ( !isSimpleValue( queryString ) ) {
            queryString = '';
        }
        return queryString;
    }

    private string function segmentLast( string segments, string delimiter ) {
        var where = find( delimiter, segments );
        if ( where ) {
            if ( where == len( segments ) ) {
                return '';
            } else {
                return right( segments, len( segments ) - where );
            }
        }
        return segments;
    }

    private string function parseViewOrLayoutPath( string path, string type ) {
        var folder = type;
        switch ( folder ) {
        case 'layout':
            folder = variables.layoutFolder;
            break;
        case 'view':
            folder = variables.viewFolder;
            break;
            // else leave it alone?
        }
        var pathInfo = { };
        var subsystem = getSubsystem( getSubsystemSectionAndItem( path ) );

        // allow for :section/action to simplify logic in setupRequestWrapper():
        pathInfo.path = segmentLast( path, variables.framework.subsystemDelimiter );
        pathInfo.base = request.base;
        pathInfo.subsystem = subsystem;
        if ( usingSubsystems() || len( subsystem ) ) {
            pathInfo.base = pathInfo.base & getSubsystemDirPrefix( subsystem );
        }
        var defaultPath = pathInfo.base & folder & 's/' & pathInfo.path & '.cfm';
        return customizeViewOrLayoutPath( pathInfo, type, defaultPath );

    }

    private struct function processRouteMatch( string route, string target, string path, string httpMethod ) {
        var regExCache = isFrameworkInitialized() ? getFw1App().cache.routes.regex : { };
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
                    var methodLen = 0;
                    if ( routeLen >= 2 && left( routeRegEx.pattern, 2 ) == '$*' ) {
                        // accept all methods so don't set method but...
                        methodLen = 2; // ...consume 2 characters
                    } else {
                        routeRegEx.method = listFirst( routeRegEx.pattern, '*/^' );
                        methodLen = len( routeRegEx.method );
                    }
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
            var placeholders = rematch( '(\{[-_a-zA-Z0-9]+:[^\}]*\})|(:[-_a-zA-Z0-9]+)|(\([^\)]+)', routeRegEx.pattern );
            for ( var placeholder in placeholders ) {
                var placeholderFirstChar = left( placeholder, 1 );
                if ( placeholderFirstChar == ':') {
                    routeRegEx.pattern = replace( routeRegEx.pattern, placeholder, '([^/]*)' );
                    routeRegEx.target = replace( routeRegEx.target, placeholder, chr(92) & n );
                }
                else if ( placeholderFirstChar == '{') {
                    var findPlaceholderSpecificRegex = refind("\{([^:]*):([^\}]*)\}", placeholder, 1, true);
                    var placeholderSpecificRegexFound = arrayLen(findPlaceholderSpecificRegex.pos) gte 3;
                    if( placeholderSpecificRegexFound ){
                        var placeholderName = mid( placeholder, findPlaceholderSpecificRegex.pos[2], findPlaceholderSpecificRegex.len[2] );
                        var placeholderSpecificRegex = mid( placeholder, findPlaceholderSpecificRegex.pos[3], findPlaceholderSpecificRegex.len[3] );
                        routeRegEx.pattern = replace( routeRegEx.pattern, placeholder, "(#placeholderSpecificRegex#)" );
                        routeRegEx.target = replace( routeRegEx.target, ":" & placeholderName, chr(92) & n );
                    }
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
        if ( routeRegexFind( routeMatch.pattern, path ) ) {
            if ( len( routeMatch.method ) > 1 ) {
                if ( '$' & httpMethod == routeMatch.method ) {
                    routeMatch.matched = true;
                } else if ( variables.framework.preflightOptions ) {
                    // it matched apart from the method so record this
                    request._fw1.routeMethodsMatched[ right( routeMatch.method, len( routeMatch.method ) - 1 ) ] = true;
                }
            } else if ( variables.framework.preflightOptions && httpMethod == "OPTIONS" ) {
                // it would have matched but we should special case OPTIONS
                request._fw1.routeMethodsMatched.get = true;
                request._fw1.routeMethodsMatched.post = true;
            } else {
                routeMatch.matched = true;
            }
            if ( routeMatch.matched ) {
                routeMatch.route = route;
                routeMatch.path = path;
            }
        }
        return routeMatch;
    }

    private numeric function routeRegexFind( string pattern, string path ) {
        if ( variables.framework.routesCaseSensitive ) {
            return reFind( pattern, path );
        } else {
            return REFindNoCase( pattern, path );
        }
    }

    private array function getResourceRoutes( any resourcesToRoute, string subsystem = '', string pathRoot = '', string targetAppend = '' ) {
        var resourceCache = isFrameworkInitialized() ? getFw1App().cache.routes.resources : { };
        var cacheKey = hash( serializeJSON( { rtr = resourcesToRoute, ss = subsystem, pr = pathRoot, ta = targetAppend } ) );
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

    private any function read_json( string json ) {
        return deserializeJSON( json );
    }

    private struct function render_json( struct renderData ) {
        return {
            contentType = 'application/json; charset=utf-8',
            output = serializeJSON( renderData.data )
        };
    }

    private struct function render_jsonp( struct renderData ) {
        if ( !structKeyExists( renderData, 'jsonpCallback' ) || !len( renderData.jsonpCallback ) ){
            throw( type = 'FW1.jsonpCallbackRequired',
                   message = 'Callback was not defined',
                   detail = 'renderData() called with jsonp type requires a jsonpCallback' );
        }
        return {
            contentType = 'application/javascript; charset=utf-8',
            output = renderData.jsonpCallback & "(" & serializeJSON( renderData.data ) & ");"
        };
    }

    private struct function render_rawjson( struct renderData ) {
        return {
            contentType = 'application/json; charset=utf-8',
            output = renderData.data
        };
    }

    private struct function render_html( struct renderData ) {
        structDelete( request._fw1, 'renderData' );
        return {
            contentType = 'text/html; charset=utf-8',
            output = renderData.data
        };
    }

    private struct function render_xml( struct renderData ) {
        var output = '';
        if ( isXML( renderData.data ) ) {
            if ( isSimpleValue( renderData.data ) ) {
                // XML as string already
                output = renderData.data;
            } else {
                // XML object
                output = toString( renderData.data );
            }
        } else {
            throw( type = 'FW1.UnsupportXMLRender',
                   message = 'Data is not XML',
                   detail = 'renderData() called with XML type but unrecognized data format' );
        }
        return {
            contentType = 'text/xml; charset=utf-8',
            output = output
        };
    }

    private struct function render_text( struct renderData ) {
        return {
            contentType = 'text/plain; charset=utf-8',
            output = renderData.data
        };
    }

    private struct function renderDataWithContentType() {
        var out = { };
        var renderType = request._fw1.renderData.type;
        var statusCode = request._fw1.renderData.statusCode;
        var statusText = request._fw1.renderData.statusText;
        var headers = structKeyExists( request._fw1.renderData, 'headers' ) ?
            request._fw1.renderData.headers : [ ];
        if ( isSimpleValue( renderType ) ) {
            var fn_type = 'render_' & renderType;
            if ( structKeyExists( variables, fn_type ) ) {
                renderType = variables[ fn_type ];
                // evaluate with no FW/1 context!
                out = renderType( request._fw1.renderData );
            } else {
                throw( type = 'FW1.UnsupportedRenderType',
                       message = 'Only HTML, JSON, JSONP, RAWJSON, XML, and TEXT are supported',
                       detail = 'renderData() called with unknown type: ' & renderType );
            }
        } else {
            // assume it is a function
            out = renderType( request._fw1.renderData );
        }
        var resp = getPageContext().getResponse();
        for ( var h in headers ) {
            resp.setHeader( h.name, h.value );
        }
        // in theory, we should use sendError() instead of setStatus() but some
        // Servlet containers interpret that to mean "Send my error page" instead
        // of just sending the response you actually want!
        if ( len( statusText ) ) {
            resp.setStatus( statusCode, statusText );
        } else {
            resp.setStatus( statusCode );
        }
        return out;
    }

    private struct function resolveBaseURL( string action = '.', string path = variables.magicBaseURL ) {
        if ( path == variables.magicBaseURL ) path = getBaseURL();
        if ( path == 'useSubsystemConfig' ) {
            var subsystemConfig = getSubsystemConfig( getSubsystem( action ) );
            if ( structKeyExists( subsystemConfig, 'baseURL' ) ) {
                path = subsystemConfig.baseURL;
            } else {
                path = getBaseURL();
            }
        }
        var omitIndex = false;
        var optionalOmit = false;
        if ( path == 'useCgiScriptName' ) {
            path = getContextRoot() & request._fw1.cgiScriptName;
            optionalOmit = true;
        } else if ( path == 'useRequestURI' ) {
            path = getPageContext().getRequest().getRequestURI();
            optionalOmit = true;
        }
        if ( optionalOmit ) {
            if ( variables.framework.SESOmitIndex ) {
                path = getDirectoryFromPath( path );
                omitIndex = true;
            }
        }
        return { path = replace( path, chr(92), '/', 'all' ), omitIndex = omitIndex };
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
            if ( sessionHas( preserveKeySessionKey ) ) {
                structAppend( request.context, sessionRead( preserveKeySessionKey ), false );
                if ( variables.framework.maxNumContextsPreserved == 1 ) {
                    /*
                      When multiple contexts are preserved, the oldest context is purged
                      within getNextPreserveKeyAndPurgeOld once the maximum is reached.
                      This allows for a browser refresh after the redirect to still receive
                      the same context.
                    */
                    sessionDelete( preserveKeySessionKey );
                }
            }
        } catch ( any e ) {
            // session scope not enabled, do nothing
        }
    }

    private string function saveFlashContext( string keys ) {
        var curPreserveKey = getNextPreserveKeyAndPurgeOld();
        var preserveKeySessionKey = getPreserveKeySessionKey( curPreserveKey );
        var tmpSession = '';
        try {
            sessionDefault( preserveKeySessionKey, {} );
            if ( keys == 'all' ) {
                tmpSession = sessionRead( preserveKeySessionKey );
                structAppend( tmpSession, request.context );
                sessionWrite( preserveKeySessionKey, tmpSession );
            } else {
                var key = 0;
                var keyNames = listToArray( keys );
                for ( key in keyNames ) {
                    key = trim( key );
                    if ( structKeyExists( request.context, key ) ) {
                        tmpSession = sessionRead( preserveKeySessionKey );
                        tmpSession[ key ] = request.context[ key ];
                        sessionWrite( preserveKeySessionKey, tmpSession);
                    } else {
                        internalFrameworkTrace( message = 'key "#key#" does not exist in RC, cannot preserve.', traceType = 'WARNING' );
                    }
                }
            }
        } catch ( any ex ) {
            // session scope not enabled, do nothing
            internalFrameworkTrace( message = 'sessionManagement not enabled, cannot preserve RC keys.', traceType = 'WARNING' );
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
            invoke( cfc, "set#property#", args );
        }
    }

    private void function setupApplicationWrapper() {
        if ( structKeyExists( request._fw1, "appWrapped" ) ) return;
        request._fw1.appWrapped = true;
        request._fw1.theApp = {
            cache = {
                lastReload = now(),
                fileExists = { },
                controllers = { },
                routes = { regex = { }, resources = { } }
            },
            subsystems = { },
            subsystemFactories = { }
        };

        switch ( variables.framework.diEngine ) {
        case "aop1":
        case "di1":
            var ioc = new "#variables.framework.diComponent#"(
                variables.framework.diLocations,
                variables.framework.diConfig
            );
            ioc.addBean( "fw", this ); // alias for controller constructor compatibility
            setBeanFactory( ioc );
            break;
        case "wirebox":
            if ( isSimpleValue( variables.framework.diConfig ) ) {
                // per #363 assume name of binder CFC
                var wb1 = new "#variables.framework.diComponent#"(
                    variables.framework.diConfig, // binder path
                    variables.framework // properties struct
                );
                // we do not provide fw alias for controller constructor here!
                setBeanFactory( wb1 );
            } else {
                // legacy configuration
                var wb2 = new "#variables.framework.diComponent#"(
                    properties = variables.framework.diConfig
                );
                wb2.getBinder().scanLocations( variables.framework.diLocations );
                // we do not provide fw alias for controller constructor here!
                setBeanFactory( wb2 );
            }
            break;
        case "custom":
            var ioc = new "#variables.framework.diComponent#"(
                variables.framework.diLocations,
                variables.framework.diConfig
            );
            setBeanFactory( ioc );
            break;
        }

        // this will recreate the main bean factory on a reload:
        internalFrameworkTrace( 'setupApplication() called' );
        setupApplication();
        application[variables.framework.applicationKey] = request._fw1.theApp;

    }

    private void function setupFrameworkDefaults() {
        if ( structKeyExists( variables, "_fw1_defaults_initialized" ) ) return;
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
            variables.framework.base = getDirectoryFromPath( request._fw1.cgiScriptName );
        }
        if ( right( variables.framework.base, 1 ) != '/' ) {
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
            variables.framework.usingSubsystems = structKeyExists( variables.framework, 'defaultSubsystem' ) ||
                structKeyExists( variables.framework, 'siteWideLayoutSubsystem' );
        }
        if ( !structKeyExists(variables.framework, 'defaultSubsystem') ) {
            variables.framework.defaultSubsystem = variables.framework.usingSubsystems ? 'home' : '';
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
        if ( !structKeyExists( variables.framework, 'subsystems' ) ) {
            variables.framework.subsystems = { };
        }
        if ( structKeyExists(variables.framework, 'home') ) {
            if ( usingSubsystems() ) {
                if ( !find( variables.framework.subsystemDelimiter, variables.framework.home ) ) {
                    throw( type = "FW1.configuration.home", message = "You are using subsystems but framework.home does not specify a subsystem.", detail = "You should set framework.home to #variables.framework.defaultSubsystem##variables.framework.subsystemDelimiter##variables.framework.home#" );
                }
            }
        } else {
            variables.framework.home = variables.framework.subsystemDelimiter & variables.framework.defaultSection & '.' & variables.framework.defaultItem;
            if ( usingSubsystems() ) {
                variables.framework.home = variables.framework.defaultSubsystem & variables.framework.home;
            }
        }
        if ( !structKeyExists(variables.framework, 'error') ) {
            variables.framework.error = variables.framework.subsystemDelimiter & variables.framework.defaultSection & '.error';
            if ( usingSubsystems() ) {
                variables.framework.error = variables.framework.defaultSubsystem & variables.framework.error;
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
        // remove trailing "/" from baseURL
        if ( len( variables.framework.baseURL ) > 1 && right( variables.framework.baseURL, 1 ) == '/' ) {
            variables.framework.baseURL = left( variables.framework.baseURL, len( variables.framework.baseURL ) - 1 );
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
        if ( structKeyExists(variables.framework, 'unhandledPaths') ) {
            // convert unhandledPaths to regex:
            var escapes = '(\+|\*|\?|\.|\[|\^|\$|\(|\)|\{|\||\\)';
            var slashMarker = '@@@@@'; // should be something that will never appear in a filename
            variables.framework.unhandledPathRegex = replace(
                replace(
                    REReplace( variables.framework.unhandledPaths, escapes, slashMarker & '\1', 'all' ),
                    slashMarker, chr(92), 'all' ),
                ',', '|', 'all' );
        } else {
            variables.framework.unhandledPaths = '/flex2gateway';
            variables.framework.unhandledPathRegex = '/flex2gateway';
        }
        if ( !structKeyExists( variables.framework, 'unhandledErrorCaught' ) ) {
            variables.framework.unhandledErrorCaught = false;
        }
        if ( !structKeyExists(variables.framework, 'applicationKey') ) {
            variables.framework.applicationKey = 'framework.one';
        }
        if ( !structKeyExists( variables.framework, 'cacheFileExists' ) ) {
            variables.framework.cacheFileExists = false;
        }
        if ( !structKeyExists( variables.framework, 'routes' ) ) {
            variables.framework.routes = [ ];
        }
        if ( !structKeyExists( variables.framework, 'perResourceError' ) ) {
            variables.framework.perResourceError = true;
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
            if ( variables.framework.perResourceError ) {
                arrayAppend( variables.framework.resourceRouteTemplates, { method = 'error', httpMethods = [ '$*' ] } );
            }
        }
        if ( !structKeyExists( variables.framework, 'routesCaseSensitive' ) ) {
            variables.framework.routesCaseSensitive = true;
        }
        if ( !structKeyExists( variables.framework, 'noLowerCase' ) ) {
            variables.framework.noLowerCase = false;
        }
        if ( !structKeyExists( variables.framework, 'trace' ) ) {
            variables.framework.trace = false;
        }
        if ( !structKeyExists( variables.framework, 'controllersFolder' ) ) {
            variables.framework.controllersFolder = 'controllers';
        }
        if ( right( variables.framework.controllersFolder, 1 ) != 's' ) {
            throw( type = "FW1.IllegalConfiguration",
                   message = "ControllersFolder must be a plural word (ends in 's')." );
        }
        variables.controllerFolder = left( variables.framework.controllersFolder, len( variables.framework.controllersFolder ) - 1 );
        if ( !structKeyExists( variables.framework, 'layoutsFolder' ) ) {
            variables.framework.layoutsFolder = 'layouts';
        }
        if ( right( variables.framework.layoutsFolder, 1 ) != 's' ) {
            throw( type = "FW1.IllegalConfiguration",
                   message = "LayoutsFolder must be a plural word (ends in 's')." );
        }
        variables.layoutFolder = left( variables.framework.layoutsFolder, len( variables.framework.layoutsFolder ) - 1 );
        if ( !structKeyExists( variables.framework, 'subsystemsFolder' ) ) {
            variables.framework.subsystemsFolder = 'subsystems';
        }
        if ( right( variables.framework.subsystemsFolder, 1 ) != 's' ) {
            throw( type = "FW1.IllegalConfiguration",
                   message = "SubsystemsFolder must be a plural word (ends in 's')." );
        }
        variables.subsystemFolder = left( variables.framework.subsystemsFolder, len( variables.framework.subsystemsFolder ) - 1 );
        if ( !structKeyExists( variables.framework, 'viewsFolder' ) ) {
            variables.framework.viewsFolder = 'views';
        }
        if ( right( variables.framework.viewsFolder, 1 ) != 's' ) {
            throw( type = "FW1.IllegalConfiguration",
                   message = "ViewsFolder must be a plural word (ends in 's')." );
        }
        variables.viewFolder = left( variables.framework.viewsFolder, len( variables.framework.viewsFolder ) - 1 );
        if ( !structKeyExists( variables.framework, 'diOverrideAllowed' ) ) {
            variables.framework.diOverrideAllowed = false;
        }
        if ( !structKeyExists( variables.framework, 'diEngine' ) ) {
            variables.framework.diEngine = 'di1';
        }
        if ( !structKeyExists( variables.framework, 'diLocations' ) ) {
            variables.framework.diLocations = 'model,' & variables.framework.controllersFolder;
        }
        if ( !structKeyExists( variables.framework, 'diConfig' ) ) {
            variables.framework.diConfig = { };
        }
        if ( !structKeyExists( variables.framework, 'diComponent' ) ) {
            var diComponent = 'framework.ioc';
            switch ( variables.framework.diEngine ) {
            case 'aop1':
                diComponent = 'framework.aop';
                break;
            case 'wirebox':
                diComponent = 'framework.WireBoxAdapter';
                break;
            case 'custom':
                throw( type="FW1.IllegalConfiguration",
                       message="If you specify diEngine='custom' you must specify a component path for diComponent." );
                break;
            default:
                // assume DI/1
                break;
            }
            variables.framework.diComponent = diComponent;
        }
        if ( structKeyExists( variables.framework, 'enableJSONPOST' ) ) {
            throw( type="FW1.IllegalConfiguration",
                   message="The enableJSONPOST setting has been renamed to decodeRequestBody." );
        }
        if ( !structKeyExists( variables.framework, 'decodeRequestBody' ) ) {
            variables.framework.decodeRequestBody = false;
        }
        if ( !structKeyExists( variables.framework, 'preflightOptions' ) ) {
            variables.framework.preflightOptions = false;
        }
        if ( !structKeyExists( variables.framework, 'optionsAccessControl' ) ) {
            variables.framework.optionsAccessControl = { };
        }
        setupEnvironment( env );
        if ( variables.framework.preflightOptions ) {
            var defaultAccessControl = {
                origin = "*",
                headers = "Accept,Authorization,Content-Type",
                credentials = true,
                maxAge = 1728000
            };
            structAppend( variables.framework.optionsAccessControl, defaultAccessControl, false );
        }
        request._fw1.doTrace = variables.framework.trace;
        // add this as a fingerprint so autowire can detect FW/1 CFC:
        this.__fw1_version = variables.framework.version;
        variables._fw1_defaults_initialized = true;
    }

    private string function setupFrameworkEnvironments() {
        var env = getEnvironment();
        if ( structKeyExists( variables.framework, 'environments' ) ) {
            var envs = variables.framework.environments;
            var tier = listFirst( env, '-' );
            if ( structKeyExists( envs, tier ) ) {
                mergeConfig( variables.framework, envs[ tier ] );
            }
            if ( env != tier && structKeyExists( envs, env ) ) {
                mergeConfig( variables.framework, envs[ env ] );
            }
        }
        return env;
    }

    private void function mergeConfig( struct target, struct source ) {
        // subsystems and diConfig should be merged
        var subsystems = structKeyExists( target, 'subsystems' ) ? structCopy( target.subsystems ) : { };
        var diConfig = structKeyExists( target, 'diConfig' ) ? structCopy( target.diConfig ) : { };
        // and diConfig has constants, singulars as sub-structs
        var constants = structKeyExists( diConfig, 'constants' ) ? structCopy( diConfig.constants ) : { };
        var singulars = structKeyExists( diConfig, 'singulars' ) ? structCopy( diConfig.singulars ) : { };
        // and diConfig has exclude, transients as sub-arrays
        var exclude = [ ];
        if ( structKeyExists( diConfig, 'exclude' ) )
            for ( var ei in diConfig.exclude )
                arrayAppend( exclude, ei );
        var transients = [ ];
        if ( structKeyExists( diConfig, 'transients' ) )
            for ( var ti in diConfig.transients )
                arrayAppend( transients, ti );
        // subsystems might have its own diConfig but that's too complex to address right now

        // merge top-level config destructively
        structAppend( target, source );

        // re-merge subsystems keys non-destructively
        if ( structKeyExists( source, 'subsystems' ) ) {
            structAppend( target.subsystems, subsystems, false );
        }
        // re-merge diConfig keys non-destructively and recurse in
        if ( structKeyExists( source, 'diConfig' ) ) {
            structAppend( target.diConfig, diConfig, false );
            if ( structKeyExists( source.diConfig, 'constants' ) ) {
                structAppend( target.diConfig.constants, constants, false );
            }
            if ( structKeyExists( source.diConfig, 'singulars' ) ) {
                structAppend( target.diConfig.singulars, singulars, false );
            }
            if ( structKeyExists( source.diConfig, 'exclude' ) ) {
                for ( ei in exclude ) arrayAppend( target.diConfig.exclude, ei );
            }
            if ( structKeyExists( source.diConfig, 'transients' ) ) {
                for ( ti in transients ) arrayAppend( target.diConfig.transients, ti );
            }
        }
    }

    private void function setupRequestDefaults() {
        setupFrameworkDefaults();
        if ( !request._fw1.requestDefaultsInitialized ) {
            var pathInfo = request._fw1.cgiPathInfo;
            request.base = variables.framework.base;
            request.cfcbase = variables.framework.cfcbase;

            if ( !structKeyExists(request, 'context') ) {
                request.context = { };
            }
            // SES URLs by popular request :)
            if ( len( pathInfo ) > len( request._fw1.cgiScriptName ) && left( pathInfo, len( request._fw1.cgiScriptName ) ) == request._fw1.cgiScriptName ) {
                // canonicalize for IIS:
                pathInfo = right( pathInfo, len( pathInfo ) - len( request._fw1.cgiScriptName ) );
            } else if ( len( pathInfo ) > 0 && pathInfo == left( request._fw1.cgiScriptName, len( pathInfo ) ) ) {
                // pathInfo is bogus so ignore it:
                pathInfo = '';
            }
            request._fw1.currentRoute = '';
            var routes = getRoutes();
            if ( arrayLen( routes ) ) {
                internalFrameworkTrace( 'processRoutes() called' );
                var routeMatch = processRoutes( pathInfo, routes );
                if ( routeMatch.matched ) {
                    internalFrameworkTrace( 'route matched - #routeMatch.route# - #pathInfo#' );
                    var routeTail = '';
                    if ( variables.framework.routesCaseSensitive ) {
                        pathInfo = rereplace( routeMatch.path, routeMatch.pattern, routeMatch.target );
                        routeTail = rereplace( routeMatch.path, routeMatch.pattern, '' );
                    } else {
                        pathInfo = rereplacenocase( routeMatch.path, routeMatch.pattern, routeMatch.target );
                        routeTail = rereplacenocase( routeMatch.path, routeMatch.pattern, '' );
                    }
                    request._fw1.currentRoute = left( routeMatch.path, len( routeMatch.path ) - len( routeTail ) );
                    if ( routeMatch.redirect ) {
                        location( pathInfo, false, routeMatch.statusCode );
                    } else {
                        request._fw1.route = routeMatch.route;
                    }
                }
            } else if ( variables.framework.preflightOptions && request._fw1.cgiRequestMethod == "OPTIONS" ) {
                // non-route matching but we have OPTIONS support enabled
                request._fw1.routeMethodsMatched.get = true;
                request._fw1.routeMethodsMatched.post = true;
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
            if ( !len( request._fw1.currentRoute ) ) {
                switch ( sesN ) {
                case 0 : request._fw1.currentRoute = '/'; break;
                case 1 : request._fw1.currentRoute = '/' & pathInfo[1] & '/'; break;
                default: request._fw1.currentRoute = '/' & pathInfo[1] & '/' & pathInfo[2] & '/'; break;
                }
            }
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
            if ( isDefined( 'URL'  ) ) structAppend( request.context, URL );
            var httpData = getHttpRequestData();
            if ( variables.framework.decodeRequestBody ) {
                // thanks to Adam Tuttle and by proxy Jason Dean and Ray Camden for the
                // seed of this code, inspired by Taffy's basic deserialization
                // also thanks to John Whish for the URL-encoded form support
                // which adds support for PUT etc
                var body = httpData.content;
                if ( isBinary( body ) ) body = charSetEncode( body, "utf-8" );
                if ( len( body ) ) {
                    switch ( listFirst( CGI.CONTENT_TYPE, ';' ) ) {
                    case "application/json":
                    case "text/json":
                        try {
                            var bodyStruct = read_json( body );
                            if ( isStruct( bodyStruct ) ) {
							    structAppend( request.context, bodyStruct );
							} else {
							    request.context[ 'body' ] = bodyStruct;
							}
                        } catch ( any e ) {
                            throw( type = "FW1.JSONPOST",
                                   message = "Content-Type implies JSON but could not deserialize body: " & e.message );
                        }
                        break;
                    case "application/x-www-form-urlencoded":
                        try {
                            var paramPairs = listToArray( body, "&" );
                            for ( var pair in paramPairs ) {
                                var parts = listToArray( pair, "=", true ); // handle blank values
                                var keyName = parts[ 1 ];
                                var keyValue = urlDecode( parts[ 2 ] );
                                if ( !structKeyExists( request.context, keyName ) ) {
                                    request.context[ keyName ] = keyValue;
                                } else {
                                    request.context[ keyName ] = listAppend( request.context[ keyName ], keyValue );
                                }
                            }
                        } catch ( any e ) {
                            throw( type = "FW1.JSONPOST",
                                   message = "Content-Type implies form encoded but could not deserialize body: " & e.message );
                        }
                        break;
                    default:
                        // ignore -- either built-in (form handling) or unsupported
                        break;
                    }
                }
            }
            if ( isDefined( 'form' ) ) structAppend( request.context, form );
            request._fw1.headers = httpData.headers;
            // figure out the request action before restoring flash context:
            if ( !structKeyExists( request.context, variables.framework.action ) ) {
                request.context[ variables.framework.action ] = getFullyQualifiedAction( variables.framework.home );
            } else {
                request.context[ variables.framework.action ] = getFullyQualifiedAction( request.context[ variables.framework.action ] );
            }
            if ( variables.framework.noLowerCase ) {
                request.action = validateAction( request.context[ variables.framework.action ] );
            } else {
                request.action = validateAction( lCase(request.context[ variables.framework.action ]) );
            }
            request._fw1.requestDefaultsInitialized = true;
        }
    }

    private void function setupRequestWrapper( boolean runSetup ) {

        request.subsystem = getSubsystem( request.action );
        request.subsystembase = request.base & getSubsystemDirPrefix( request.subsystem );
        request.section = getSection( request.action );
        request.item = getItem( request.action );
        request._fw1.theFramework = this; // for use in the facade (only!)

        if ( runSetup ) {
            controller( variables.magicApplicationSubsystem & variables.framework.subsystemDelimiter &
                        variables.magicApplicationController & '.' & variables.magicApplicationAction );
            setupSubsystemWrapper( request.subsystem );
            internalFrameworkTrace( 'setupRequest() called' );
            setupRequest();
        }

        controller( request.action );
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
        if ( !len( subsystem ) ) return;
        if ( !isSubsystemInitialized( subsystem ) ) {
            lock name="fw1_#application.applicationName#_#variables.framework.applicationKey#_subsysteminit_#subsystem#" type="exclusive" timeout="30" {
                if ( !isSubsystemInitialized( subsystem ) ) {
                    getFw1App().subsystems[ subsystem ] = now();
                    // Application.cfc does not get a subsystem bean factory!
                    if ( subsystem != variables.magicApplicationSubsystem ) {
                        var subsystemConfig = getSubsystemConfig( subsystem );
                        var diEngine = structKeyExists( subsystemConfig, 'diEngine' ) ? subsystemConfig.diEngine : variables.framework.diEngine;
                        if ( diEngine == "di1" || diEngine == "aop1" ) {
                            // we can only reliably automate D/I engine setup for DI/1 / AOP/1
                            var diLocations = structKeyExists( subsystemConfig, 'diLocations' ) ? subsystemConfig.diLocations : variables.framework.diLocations;
                            var locations = isSimpleValue( diLocations ) ? listToArray( diLocations ) : diLocations;
                            var subLocations = "";
                            for ( var loc in locations ) {
                                var relLoc = trim( loc );
                                // make a relative location:
                                if ( len( relLoc ) > 2 && left( relLoc, 2 ) == "./" ) {
                                    relLoc = right( relLoc, len( relLoc ) - 2 );
                                } else if ( len( relLoc ) > 1 && left( relLoc, 1 ) == "/" ) {
                                    relLoc = right( relLoc, len( relLoc ) - 1 );
                                }
                                if ( usingSubsystems() ) {
                                    subLocations = listAppend( subLocations, variables.framework.base & subsystem & "/" & relLoc );
                                } else {
                                    subLocations = listAppend( subLocations, variables.framework.base & variables.framework.subsystemsFolder & "/" & subsystem & "/" & relLoc );
                                }
                            }
                            if ( len( sublocations ) ) {
                                var diComponent = structKeyExists( subsystemConfig, 'diComponent' ) ? subsystemConfig : variables.framework.diComponent;
                                var cfg = { };
                                if ( structKeyExists( subsystemConfig, 'diConfig' ) ) {
                                    cfg = subsystemConfig.diConfig;
                                } else {
                                    cfg = structCopy( variables.framework.diConfig );
                                    structDelete( cfg, 'loadListener' );
                                }
                                cfg.noClojure = true;
                                var ioc = new "#diComponent#"( subLocations, cfg );
                                ioc.setParent( getDefaultBeanFactory() );
                                setSubsystemBeanFactory( subsystem, ioc );
                            }
                        }
                    }

                    internalFrameworkTrace( 'setupSubsystem() called', subsystem );
                    setupSubsystem( subsystem );
                }
            }
        }
    }

    private string function validateAction( string action ) {
        // check for forward and backward slash in the action - using chr() to avoid confusing TextMate (Hi Nathan!)
        if ( findOneOf( chr(47) & chr(92), action ) > 0 ) {
            throw( type='FW1.actionContainsSlash', message="Found a slash in the action: '#action#'.",
                   detail='Actions are not allowed to embed sub-directory paths.');
        }
        return action;
    }

    private void function viewNotFound() {
        // request.missingView should always be set after issue #280
        // but this will prevent an exception while attempting to throw
        // the exception we actually want to throw!
        param name="request.missingView" default="<unknown.view>";
        throw( type='FW1.viewNotFound', message="Unable to find a view for '#request.action#' action.",
               detail="'#request.missingView#' does not exist." );
    }

}
