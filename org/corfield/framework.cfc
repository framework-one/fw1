<cfcomponent><cfscript>
/*
	Copyright (c) 2009, Sean Corfield

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

	/*
	 * call this from your setupApplication() method to tell the framework
	 * about your bean factory - only assumption is that it supports:
	 * - containsBean(name) - returns true if factory contains that named bean, else false
	 * - getBean(name) - returns the named bean
	 */
	function setBeanFactory(factory) {
	
		application[variables.framework.applicationKey].factory = factory;
	
	}

	/*
	 * override this to provide application-specific initialization
	 * if you want the framework to use a bean factory and autowire
	 * controllers and services, call setBeanFactory(factory) in your
	 * setupApplication() method
	 * you do not need to call super.setupApplication()
	 */
	function setupApplication() { }

	/*
	 * override this to provide session-specific initialization
	 * you do not need to call super.setupSession()
	 */
	function setupSession() { }

	/*
	 * override this to provide request-specific initialization
	 * you do not need to call super.setupRequest()
	 */
	function setupRequest() { }

	/*
	 * call this from your controller to queue up additional services
	 */
	function service( action, key ) {
		
		var section = getSection( action );
		var item = getItem( action );
		var tuple = structNew();
		
		tuple.service = getService(section);
		tuple.item = item;
		tuple.key = key;
		
		if ( structKeyExists( tuple, "service" ) ) {
			arrayAppend( request.services, tuple );
		}
	}
	
	/*
	 * it is better to set up your application configuration in
	 * your setupApplication() method since that is called on a
	 * framework reload
	 * if you do override onApplicationStart(), you must call
	 * super.onApplicationStart() first
	 */
	function onApplicationStart() {
		setupFrameworkDefaults();
		setupApplicationWrapper();
	}
	
	/*
	 * it is better to set up your session configuration in
	 * your setupSession() method
	 * if you do override onSessionStart(), you must call
	 * super.onSessionStart() first
	 */
	function onSessionStart() {
		setupFrameworkDefaults();
		setupSession();
	}
	
	/*
	 * it is better to set up your request configuration in
	 * your setupRequest() method
	 * if you do override onRequestStart(), you must call
	 * super.onRequestStart() first
	 */
	function onRequestStart(targetPath) {
		
		var pathInfo = CGI.PATH_INFO;
		var sesIx = 0;
		
		setupFrameworkDefaults();
		
		if ( isDefined('URL') and 
				structKeyExists(URL, variables.framework.reload) and 
				URL[variables.framework.reload] is variables.framework.password ) {
			setupApplicationWrapper();
		}
		
		if ( structKeyExists(variables.framework, 'base') ) {
			request.base = variables.framework.base;
			if ( right(request.base,1) is not '/' ) {
				request.base = request.base & '/';
			}
		} else {
			request.base = getDirectoryFromPath(targetPath);
		}
		request.base = replace( request.base, chr(92), '/', 'all' );
		if ( structKeyExists(variables.framework, 'cfcbase') ) {
			request.cfcbase = variables.framework.cfcbase;
		} else {
			if ( len(request.base) eq 1 ) {
				request.cfcbase = '';
			} else {
				request.cfcbase = replace( mid(request.base, 2, len(request.base)-2 ), '/', '.', 'all' );
			}
		}

		if ( not structKeyExists(request, 'context') ) {
			request.context = structNew();
		}
		restoreFlashContext();
		// SES URLs by popular request :)
		if ( len( pathInfo ) gt len( CGI.SCRIPT_NAME ) and left( pathInfo, len( CGI.SCRIPT_NAME ) ) is CGI.SCRIPT_NAME ) {
			// canonicalize for IIS:
			pathInfo = right( pathInfo, len( pathInfo ) - len( CGI.SCRIPT_NAME ) );
		} else if ( len( pathInfo ) gt 0 and pathInfo is left( CGI.SCRIPT_NAME, len( pathInfo ) ) ) {
			// pathInfo is bogus so ignore it:
			pathInfo = '';
		}
		pathInfo = listToArray( pathInfo, '/' );
		for ( sesIx = 1; sesIx lte arrayLen( pathInfo ); sesIx = sesIx + 1 ) {
			if ( sesIx eq 1 ) {
				request.context[variables.framework.action] = pathInfo[sesIx];
			} else if ( sesIx eq 2 ) {
				request.context[variables.framework.action] = pathInfo[sesIx-1] & '.' & pathInfo[sesIx];
			} else if ( sesIx mod 2 eq 1 ) {
				request.context[ pathInfo[sesIx] ] = '';
			} else {
				request.context[ pathInfo[sesIx-1] ] = pathInfo[sesIx];
			}
		}
		// certain remote calls do not have URL or form scope:
		if ( isDefined('URL') ) structAppend(request.context,URL);
		if ( isDefined('form') ) structAppend(request.context,form);

		if ( not structKeyExists(request.context, variables.framework.action) ) {
			request.context[variables.framework.action] = variables.framework.home;
		}
		// TODO: consider listLen() gt 2:
		if ( listLen(request.context[variables.framework.action], '.') eq 1 ) {
			request.context[variables.framework.action] = request.context[variables.framework.action] & '.' & variables.framework.defaultItem;
		}
		request.action = lCase(request.context[variables.framework.action]);

		setupRequestWrapper();
		
		// allow CFC requests through directly:
		if ( right(targetPath,4) is '.cfc' or targetPath is '/flex2gateway' ) {
			structDelete(this, 'onRequest');
			structDelete(variables, 'onRequest');
		}
	}
	
	/*
	 * not intended to be overridden, automatically deleted for CFC requests
	 */
	function onRequest(targetPath) {
		
		var out = 0;
		var i = 0;
		var svc = 0;
		var _data_fw1 = 0;
		
		if ( structKeyExists( request, 'controller' ) ) {
			doController( request.controller, 'before' );
			doController( request.controller, 'start' & request.item );
			doController( request.controller, request.item );
		}
		for ( i = 1; i lte arrayLen(request.services); i = i + 1 ) {
			svc = request.services[i];
			if ( svc.key is '' ) {
				// throw the result away:
				doService( svc.service, svc.item );
			} else {
				_data_fw1 = doService( svc.service, svc.item );
				if ( isDefined('_data_fw1') ) {
					request.context[ svc.key ] = _data_fw1;
				}
			}
		}
		if ( structKeyExists( request, 'controller' ) ) {
			doController( request.controller, 'end' & request.item );
			doController( request.controller, 'after' );
		}
		if ( not structKeyExists(request, 'view') ) {
			// unable to find a matching view - fail with a nice exception
			viewNotFound();
		}
		out = view( request.view );
		for ( i = 1; i lte arrayLen(request.layouts); i = i + 1 ) {
			out = layout( request.layouts[i], out );
			if ( structKeyExists(request, 'layout') and not request.layout ) {
				break;
			}
		}
		writeOutput( out );
	}
	
	/*
	 * can be overridden, calling super.onError(exception,event) is optional
	 * depending on what error handling behavior you want
	 * note: you need to rename / disable onError() on OpenBD since it does
	 * not seem to be passed exception or event correctly when something fails
	 * in the code...
	 */
	function onError(exception,event) {

		try {
			if ( structKeyExists( request, 'action' ) ) {
				request.failedAction = request.action;
			}
			request.action = variables.framework.error;
			request.exception = exception;
			request.event = event;
			setupRequestWrapper();
			onRequest('');
		} catch (any e) {
			failure(exception,event);
		}

	}
	
	/*
	 * returns whatever the framework has been told is a bean factory
	 */
	function getBeanFactory() {
		
		return application[variables.framework.applicationKey].factory;
	}
	
	/*
	 * returns true iff the framework has been told about a bean factory
	 */
	function hasBeanFactory() {
		
		return structKeyExists(application[variables.framework.applicationKey], 'factory');
	}
	
	/*
	 * return the action URL variable name - allows applications to build URLs
	 */
	function getAction() {
		return variables.framework.action;
	}
	
	/*
	 * return the item part of the action
	 */
	function getItem( action ) {
		// TODO: consider listLen() gt 2:
		return listLast( action, '.' );
	}
	
	/*
	 * return the section part of the action
	 */
	function getSection( action ) {
		// TODO: consider listLen() gt 2:
		return listFirst( action, '.' );
	}
	
	/*
	 * return the default service result key
	 * override this if you want the default service result to be
	 * stored under a different request context key, based on the
	 * requested action, e.g., return getSection( action );
	 */
	function getServiceKey( action ) {
		return "data";
	}
	
	/*
	 * do not call/override - set your framework configuration
	 * using variables.framework = { key/value pairs} in the pseudo-constructor
	 * of your Application.cfc
	 */
	function setupFrameworkDefaults() { // "private"

		// default values for Application::variables.framework structure:
		if ( not structKeyExists(variables, 'framework') ) {
			variables.framework = structNew();
		}
		if ( not structKeyExists(variables.framework, 'action') ) {
			variables.framework.action = 'action';
		}
		if ( not structKeyExists(variables.framework, 'defaultSection') ) {
			variables.framework.defaultSection = 'main';
		}
		if ( not structKeyExists(variables.framework, 'defaultItem') ) {
			variables.framework.defaultItem = 'default';
		}
		if ( not structKeyExists(variables.framework, 'home') ) {
			variables.framework.home = variables.framework.defaultSection & '.' & variables.framework.defaultItem;
		}
		if ( not structKeyExists(variables.framework, 'error') ) {
			variables.framework.error = variables.framework.defaultSection & '.error';
		}
		if ( not structKeyExists(variables.framework, 'reload') ) {
			variables.framework.reload = 'reload';
		}
		if ( not structKeyExists(variables.framework, 'password') ) {
			variables.framework.password = 'true';
		}
		if ( not structKeyExists(variables.framework, 'applicationKey') ) {
			variables.framework.applicationKey = 'org.corfield.framework';
		}
		variables.framework.version = '0.6.4.2';

	}

	/*
	 * do not call/override
	 */
	function setupApplicationWrapper() { // "private"

		var framework = structNew();
		
		framework.cache = structNew();

		framework.cache.lastReload = now();
		framework.cache.controllers = structNew();
		framework.cache.services = structNew();

		application[variables.framework.applicationKey] = framework;
		setupApplication();

	}
	
	/*
	 * do not call/override
	 */
	function setupSessionWrapper() { // "private"
		setupSession();
	}

	/*
	 * do not call/override
	 */
	function setupRequestWrapper() { // "private"
	
		request.section = getSection(request.action);
		request.item = getItem(request.action);

		request.controller = getController(request.section);
		
		request.services = arrayNew(1);
		service( request.action, getServiceKey( request.action ) );
		
		if ( fileExists( expandPath( request.base & 'views/' & request.section & '/' & request.item & '.cfm' ) ) ) {
			request.view = request.section & '/' & request.item;
		}
		
		request.layouts = arrayNew(1);
		// look for item-specific layout:
		if ( fileExists( expandPath( request.base & 'layouts/' & request.section & '/' & request.item & '.cfm' ) ) ) {
			arrayAppend(request.layouts, request.section & '/' & request.item);
		}
		// look for section-specific layout:
		if ( fileExists( expandPath( request.base & 'layouts/' & request.section & '.cfm' ) ) ) {
			arrayAppend(request.layouts, request.section);
		}
		// look for site-wide layout:
		if ( request.section is not 'default' and
				fileExists( expandPath( request.base & 'layouts/default.cfm' ) ) ) {
			arrayAppend(request.layouts, 'default');
		}
		
		setupRequest();

	}
	
	/*
	 * do not call/override
	 */
	function getController(section) { // "private"
		var _controller_fw1 = getCachedComponent("controller",section);
		if ( isDefined('_controller_fw1') ) {
			return _controller_fw1;
		}
	}
	
	/*
	 * do not call/override
	 */
	function getService(section) { // "private"
		var _service_fw1 = getCachedComponent("service",section);
		if ( isDefined('_service_fw1') ) {
			return _service_fw1;
		}
	}
	
	/*
	 * do not call/override
	 */
	function failure(exception,event) { // "private"
	
		if ( structKeyExists(exception, 'rootCause') ) {
			exception = exception.rootCause;
		}
		writeOutput( '<h1>Exception in #event#</h1>' );
		if ( structKeyExists( request, 'failedAction' ) ) {
			writeOutput( '<p>The action #request.failedAction# failed.</p>' );
		}
		writeOutput( '<h2>#exception.message#</h2>' );
		writeOutput( '<p>#exception.detail# (#exception.type#)</p>' );
		dumpException(exception);
	
	}

</cfscript><cfsilent>
	
	<!---
		layout() may be invoked inside views and layouts
	--->
	<cffunction name="layout" output="false" hint="Returns the UI generated by the named layout.">
		<cfargument name="path" />
		<cfargument name="body" />
		
		<cfset var rc = request.context />
		<cfset var response = '' />
		<cfset var local = structNew() />
		
		<cfsavecontent variable='response'><cfinclude template="#request.base#layouts/#arguments.path#.cfm"/></cfsavecontent>
		
		<cfreturn response />
	</cffunction>
	
	<!---
		populate() may be invoked inside controllers
	--->
	<cffunction name="populate" access="public" output="false" 
			hint="Used to populate beans from the request context.">
		<cfargument name="cfc" />
		<cfargument name="keys" default="" />
		
		<cfset var key = 0 />
		<cfset var property = 0 />
		<cfset var args = 0 />
		
		<cfif arguments.keys is "">
			<cfloop item="key" collection="#arguments.cfc#">
				<cfif len(key) gt 3 and left(key,3) is "set">
					<cfset property = right(key, len(key)-3) />
					<cfif structKeyExists(request.context,property)>
						<cfset args = structNew() />
						<cfset args[property] = request.context[property] />
						<cfinvoke component="#arguments.cfc#" method="#key#" argumentCollection="#args#" />
					</cfif>
				</cfif>
			</cfloop>
		<cfelse>
			<cfloop index="property" list="#arguments.keys#">
				<cfset key = "set" & property />
				<cfif structKeyExists( arguments.cfc, key )>
					<cfif structKeyExists(request.context,property)>
						<cfset args = structNew() />
						<cfset args[property] = request.context[property] />
						<cfinvoke component="#arguments.cfc#" method="#key#" argumentCollection="#args#" />
					</cfif>
				</cfif>
			</cfloop>
		</cfif>
		
	</cffunction>
	
	<!---
		redirect() may be invoked inside controllers
	--->
	<cffunction name="redirect" access="public" output="false" 
			hint="Redirect to the specified action, optionally append specified request context items - or use session.">
		<cfargument name="action" type="string" />
		<cfargument name="preserve" type="string" default="none" />
		<cfargument name="append" type="string" default="none" />
		<cfargument name="path" type="string" default="#CGI.SCRIPT_NAME#" />
		
		<cfset var queryString = "" />
		<cfset var key = "" />
		
		<cfif arguments.preserve is not "none">
			<cfset saveFlashContext(arguments.preserve) />
		</cfif>
		
		<cfif arguments.append is not "none">
			<cfif arguments.append is "all">
				<cfloop item="key" collection="#request.context#">
					<cfif isSimpleValue( request.context[key] )>
						<cfset queryString = queryString & "&" & key & "=" & urlEncodedFormat( request.context[key] ) />
					</cfif>
				</cfloop>
			<cfelse>
				<cfloop index="key" list="#arguments.append#">
					<cfif structKeyExists( request.context, key ) and isSimpleValue( request.context[key] )>
						<cfset queryString = queryString & "&" & key & "=" & urlEncodedFormat( request.context[key] ) />
					</cfif>
				</cfloop>
			</cfif>
		</cfif>

		<cflocation url="#arguments.path#?#framework.action#=#arguments.action##queryString#" addtoken="false" />
		
	</cffunction>
	
	<!---
		view() may be invoked inside views and layouts
	--->
	<cffunction name="view" output="false" hint="Returns the UI generated by the named view. Can be called from layouts.">
		<cfargument name="path" />
		
		<cfset var rc = request.context />
		<cfset var response = '' />
		<cfset var local = structNew() />
		
		<cfsavecontent variable='response'><cfinclude template="#request.base#views/#arguments.path#.cfm"/></cfsavecontent>
		
		<cfreturn response />

	</cffunction>
	
	<!---
		the following methods should not be invoked by user code nor overridden
	--->
	
	<cffunction name="autowire" access="private" output="false" 
			hint="Used to autowire controllers and services from a bean factory.">
		<cfargument name="cfc" />
		
		<cfset var key = 0 />
		<cfset var property = 0 />
		<cfset var args = 0 />
		
		<cfloop item="key" collection="#arguments.cfc#">
			<cfif len(key) gt 3 and left(key,3) is "set">
				<cfset property = right(key, len(key)-3) />
				<cfif getBeanFactory().containsBean(property)>
					<!--- args = [ getBeanFactory().getBean(property) ] does not seem to be portable --->
					<cfset args = structNew() />
					<cfset args[property] = getBeanFactory().getBean(property) />
					<cfinvoke component="#arguments.cfc#" method="#key#" argumentCollection="#args#" />
				</cfif>
			</cfif>
		</cfloop>
		
	</cffunction>
	
	<cffunction name="getCachedComponent" access="private" output="false">
		<cfargument name="type" type="string" />
		<cfargument name="section" type="string" />
		
		<cfset var cache = application[variables.framework.applicationKey].cache />
		<cfset var types = type & 's' />
		<cfset var cfc = 0 />
		
		<cfif not structKeyExists(cache[types], section)>
			<cflock name="fw1_#application.applicationName#_#variables.framework.applicationKey#_#type#_#section#" type="exclusive" timeout="30">
				<cfscript>
					
					if ( not structKeyExists(cache[types], section)) {

						if ( hasBeanFactory() and getBeanFactory().containsBean( section & type ) ) {

							cfc = getBeanFactory().getBean( section & type );

						} else if ( fileExists( expandPath( cfcFilePath( request.cfcbase ) & types & '/' & section & '.cfc' ) ) ) {

							if ( request.cfcbase is '' ) {
								cfc = createObject( 'component', types & '.' & section );
							} else {
								cfc = createObject( 'component', request.cfcbase & '.' & types & '.' & section );
							}
							if ( structKeyExists( cfc, 'init' ) ) {
								if ( type is 'controller' ) {
									cfc.init( this );
								} else {
									cfc.init();
								}
							}

							if ( hasBeanFactory() ) {
								autowire( cfc );
							}
						}
						
						if ( isObject(cfc) ) {
							cache[types][section] = cfc;
						}
					}
					
				</cfscript>
			</cflock>
		</cfif>
		
		<cfif structKeyExists(cache[types], section)>
			<cfreturn cache[types][section] />
		</cfif>
		<!--- else "return null" effectively --->
	</cffunction>
	
	<cffunction name="cfcFilePath" access="private" output="false" hint="Changes a dotted path to a filesystem path">
		<cfargument name="dottedPath" />
		
		<cfreturn '/' & replace( arguments.dottedPath, '.', '/', 'all' ) & '/' />
		
	</cffunction>
	
	<cffunction name="doController" access="private" output="false" hint="Executes a controller in context.">
		<cfargument name="cfc" />
		<cfargument name="method" />
		
		<cfif structKeyExists(arguments.cfc,arguments.method) or structKeyExists(arguments.cfc,"onMissingMethod")>
			<cfinvoke component="#arguments.cfc#" method="#arguments.method#" rc="#request.context#" />
		</cfif>

	</cffunction>
	
	<cffunction name="doService" access="private" output="false" hint="Executes a controller in context.">
		<cfargument name="cfc" />
		<cfargument name="method" />
		
		<cfset var _result_fw1 = 0 />
		
		<cfif structKeyExists(arguments.cfc,arguments.method) or structKeyExists(arguments.cfc,"onMissingMethod")>
			<cfinvoke component="#arguments.cfc#" method="#arguments.method#"
				argumentCollection="#request.context#" returnVariable="_result_fw1" />
			<cfif isDefined("_result_fw1")>
				<cfreturn _result_fw1 />
			</cfif>
		</cfif>

	</cffunction>
	
	<cffunction name="dumpException" access="private" hint="Convenience method to dump an exception cleanly.">
		<cfargument name="exception" />
		
		<cfdump var="#arguments.exception#" label="Exception"/>
		
	</cffunction>
	
	<cffunction name="restoreFlashContext" access="private" hint="Restore request context from session scope if present.">
		
		<cftry>
			<cfif structKeyExists(session,"__fw1")>
				<cfset structAppend(request.context,session.__fw1) />
				<cfset structDelete(session,"__fw1") />
			</cfif>
		<cfcatch type="any">
			<!--- session scope not enabled, do nothing --->
		</cfcatch>
		</cftry>
		
	</cffunction>
	
	<cffunction name="saveFlashContext" access="private" hint="Save request context to session scope if present.">
		<cfargument name="keys" type="string" />
		
		<cfset var key = "" />
		
		<cftry>
			<cfparam name="session.__fw1" default="#structNew()#" />
			<cfif arguments.keys is "all">
				<cfset structAppend(session.__fw1,request.context) />
			<cfelse>
				<cfloop index="key" list="#arguments.keys#">
					<cfif structKeyExists(request.context,key)>
						<cfset session.__fw1[key] = request.context[key] />
					</cfif>
				</cfloop>
			</cfif>
		<cfcatch type="any">
			<!--- session scope not enabled, do nothing --->
		</cfcatch>
		</cftry>
		
	</cffunction>
	
	<cffunction name="viewNotFound" access="private" output="false" hint="Throw a nice, user-friendly exception.">
		
		<cfthrow type="FW1.viewNotFound" message="Unable to find a view for '#request.action#' action." 
				detail="Either 'views/#request.section#/#request.item#.cfm' does not exist or variables.framework.base is not set correctly." />
		
	</cffunction>
	
</cfsilent></cfcomponent>