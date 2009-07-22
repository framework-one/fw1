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
		
		setupFrameworkDefaults();
		
		if ( structKeyExists(URL, variables.framework.reload) and 
				URL[variables.framework.reload] is variables.framework.password ) {
			setupApplicationWrapper();
		}
		
		if ( structKeyExists(variables.framework, 'base') ) {
			request.base = variables.framework.base;
			if ( right(request.base,1) is not '/' ) {
				request.base &= '/';
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

		if ( !structKeyExists(request, 'context') ) {
			request.context = { };
		}
		structAppend(request.context,URL);
		structAppend(request.context,form);

		if ( !structKeyExists(request.context, variables.framework.action) ) {
			request.context[variables.framework.action] = variables.framework.home;
		}
		if ( listLen(request.context[variables.framework.action], '.') eq 1 ) {
			request.context[variables.framework.action] &= '.default';
		}
		request.action = request.context[variables.framework.action];

		setupRequestWrapper();
		
		// allow CFC requests through directly:
		if ( right(targetPath,4) is '.cfc' ) {
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
		
		if ( structKeyExists( request, 'controller' ) ) {
			doController( request.controller, 'before' );
			doController( request.controller, 'start' & request.item );
			doController( request.controller, request.item );
		}
		if ( structKeyExists( request, 'service' ) ) {
			doService( request.service, request.item );
		}
		if ( structKeyExists( request, 'controller' ) ) {
			doController( request.controller, 'end' & request.item );
			doController( request.controller, 'after' );
		}
		if ( !structKeyExists(request, 'view') ) {
			// unable to find a matching view - fail with a nice exception
			viewNotFound();
		}
		out = view( request.view );
		for (i = 1; i lte arrayLen(request.layouts); ++i) {
			out = layout( request.layouts[i], out );
			if ( structKeyExists(request, 'layout') and !request.layout ) {
				break;
			}
		}
		writeOutput( out );
	}
	
	/*
	 * can be overridden, calling super.onError(exception,event) is optional
	 * depending on what error handling behavior you want
	 */
	function onError(exception,event) {

		try {
			request.action = variables.framework.error;
			request.exception = exception;
			request.event = event;
			setupRequestWrapper();
			onRequest('');
		} catch (any e) {
			fail(exception,event);
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
	 * do not call/override - set your framework configuration
	 * using variables.framework = { key/value pairs} in the pseudo-constructor
	 * of your Application.cfc
	 */
	function setupFrameworkDefaults() { // "private"

		// default values for Application::variables.framework structure:
		if ( !structKeyExists(variables, 'framework') ) {
			variables.framework = { };
		}
		if ( !structKeyExists(variables.framework, 'action') ) {
			variables.framework.action = 'action';
		}
		if ( !structKeyExists(variables.framework, 'home') ) {
			variables.framework.home = 'main.default';
		}
		if ( !structKeyExists(variables.framework, 'error') ) {
			variables.framework.error = 'main.error';
		}
		if ( !structKeyExists(variables.framework, 'reload') ) {
			variables.framework.reload = 'reload';
		}
		if ( !structKeyExists(variables.framework, 'password') ) {
			variables.framework.password = 'true';
		}
		if ( !structKeyExists(variables.framework, 'applicationKey') ) {
			variables.framework.applicationKey = 'org.corfield.framework';
		}

	}

	/*
	 * do not call/override
	 */
	function setupApplicationWrapper() { // "private"

		var framework = {
				cache = {
					lastReload = now(),
					controllers = { },
					services = { }
				}
			};
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
	
		// TODO: consider listLen(request.action,'.') gt 2
		request.section = listFirst(request.action, '.');
		request.item = listLast(request.action, '.');

		request.controller = getController(request.section);
		
		request.service = getService(request.section);
		
		if ( fileExists( expandPath( request.base & 'views/' & request.section & '/' & request.item & '.cfm' ) ) ) {
			request.view = request.section & '/' & request.item;
		}
		
		request.layouts = [ ];
		// look for item-specific layout:
		if ( fileExists( expandPath( request.base & 'layouts/' & request.section & '/' & request.item & '.cfm' ) ) ) {
			arrayAppend(request.layouts, request.section & '/' & request.item);
		}
		// look for section-specific layout:
		if ( fileExists( expandPath( request.base & 'layouts/' & request.section & '.cfm' ) ) ) {
			arrayAppend(request.layouts, request.section);
		}
		// look for site-side layout:
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
		var controller = getCachedComponent("controller",section);
		if ( isDefined('controller') ) {
			return controller;
		}
	}
	
	/*
	 * do not call/override
	 */
	function getService(section) { // "private"
		var service = getCachedComponent("service",section);
		if ( isDefined('service') ) {
			return service;
		}
	}
	
	function fail(exception,event) { // "private"
	
		if ( structKeyExists(exception, 'rootCause') ) {
			exception = exception.rootCause;
		}
		writeOutput( '<h1>Exception in #event#</h1>' );
		writeOutput( '<h2>#exception.message#</h2>' );
		writeOutput( '<p>#exception.detail# (#exception.type#)</p>' );
		dumpException(exception);
	
	}

</cfscript><cfsilent>
	
	<!---
		view() may be invoked inside views and layouts
	--->
	<cffunction name="view" output="false" hint="Returns the UI generated by the named view. Can be called from layouts.">
		<cfargument name="path" />
		
		<cfset var rc = request.context />
		<cfset var response = '' />
		<cfset var local = { } />
		
		<cfsavecontent variable='response'><cfinclude template="#request.base#views/#arguments.path#.cfm"/></cfsavecontent>
		
		<cfreturn response />

	</cffunction>
	
	<!---
		layout() may be invoked inside views and layouts
	--->
	<cffunction name="layout" output="false" hint="Returns the UI generated by the named layout.">
		<cfargument name="path" />
		<cfargument name="body" />
		
		<cfset var rc = request.context />
		<cfset var response = '' />
		<cfset var local = { } />
		
		<cfsavecontent variable='response'><cfinclude template="#request.base#layouts/#arguments.path#.cfm"/></cfsavecontent>
		
		<cfreturn response />
	</cffunction>
	
	<!---
		populate() may be invoked inside controllers
	--->
	<cffunction name="populate" access="public" output="false" 
			hint="Used to populate beans from the request context.">
		<cfargument name="cfc" />
		
		<cfset var key = 0 />
		<cfset var property = 0 />
		<cfset var args = 0 />
		
		<cfloop item="key" collection="#arguments.cfc#">
			<cfif len(key) gt 3 and left(key,3) is "set">
				<cfset property = right(key, len(key)-3) />
				<cfif structKeyExists(request.context,property)>
					<cfset args = [ request.context[property] ] />
					<cfinvoke component="#arguments.cfc#" method="#key#" argumentCollection="#args#" />
				</cfif>
			</cfif>
		</cfloop>
		
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
					<cfset args = { } />
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
		
		<cfif !structKeyExists(cache[types], section)>
			<cflock name="fw1_#application.applicationName#_#variables.framework.applicationKey#_#type#_#section#" type="exclusive" timeout="30">
				<cfscript>
					
					if ( !structKeyExists(cache[types], section)) {
						
						if ( hasBeanFactory() and getBeanFactory().containsBean( section & type ) ) {

							cfc = getBeanFactory().getBean( section & type );

						} else if ( fileExists( expandPath( request.base & types & '/' & section & '.cfc' ) ) ) {

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
	
	<cffunction name="doController" access="private" output="false" hint="Executes a controller in context.">
		<cfargument name="cfc" />
		<cfargument name="method" />
		
		<cfif structKeyExists(arguments.cfc,arguments.method)>
			<cfinvoke component="#arguments.cfc#" method="#arguments.method#" rc="#request.context#" />
		</cfif>

	</cffunction>
	
	<cffunction name="doService" access="private" output="false" hint="Executes a controller in context.">
		<cfargument name="cfc" />
		<cfargument name="method" />
		
		<cfif structKeyExists(arguments.cfc,arguments.method)>
			<cfinvoke component="#arguments.cfc#" method="#arguments.method#"
				argumentCollection="#request.context#" returnVariable="request.context.data" />
		</cfif>

	</cffunction>
	
	<cffunction name="viewNotFound" access="private" output="false" hint="Throw a nice, user-friendly exception.">
		
		<cfthrow type="FW1.viewNotFound" message="Unable to find a view for '#request.action#' action." 
				detail="Either 'views/#request.section#/#request.item#.cfm' does not exist or variables.framework.base is not set correctly." />
		
	</cffunction>
	
	<cffunction name="dumpException" access="private" hint="Convenience method to dump an exception cleanly.">
		<cfargument name="exception" />
		
		<cfdump var="#arguments.exception#" label="Exception"/>
		
	</cffunction>
	
</cfsilent></cfcomponent>