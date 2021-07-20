component accessors="true" {

	property name="routes" default="#[ ]#";
	property name="preflightOptions" default="false";
	property name="optionsAccessControl" default="#{}#";
	property name="routesCaseSensitive" default="true";
	property name="resourceCache" default="#{}#"
	property name="regExCache" default="#{}#"

	public any function init(
		array routes=[],
		boolean preflightOptions=false,
		struct optionsAccessControl={}
		boolean routesCaseSensitive=true
	){
		setRoutes( routes );
		setPreflightOptions( preflightOptions );
		setOptionsAccessControl( optionsAccessControl );
		routesCaseSensitive( routesCaseSensitive );

		return this;
	}

	public void function addRoute( required any routes, string target, any methods = [ ], string statusCode = '' ) {
		var currentRoutes = getRoutes();
        var newRoutes = isArray( routes ) ? routes : [ routes ];
        var newMethods = isArray( methods ) ? methods : [ methods ];
		var newTarget = len( statusCode ) ? statusCode & ':' & target : target;

        for ( var route in newRoutes ) {
            if ( arrayLen( newMethods ) ) {
                for ( var method in newMethods ) {
                    arrayAppend( currentRoutes, { '$#method##route#' = newTarget } );
                }
            } else {
                arrayAppend( currentRoutes, { '#route#' = newTarget } );
            }
        }
        setRoutes( currentRoutes );
    }

	public struct function processRoutes( string path, array routes, string httpMethod = request._fw1.cgiRequestMethod ) {
		for ( var routePack in routes ) {
			for ( var route in routePack ) {
				if ( route == 'hint' ){
					continue;
				}
				var routeMatch = "";
				if ( route == '$RESOURCES' ) {
					routeMatch = processRoutes( path, getResourceRoutes( routePack[ route ] ), httpMethod );
				} else {
					routeMatch = processRouteMatch( route, routePack[ route ], path, httpMethod );
				}
				if ( routeMatch.matched ){
					return routeMatch;
				}
			}
		}
		return {
			matched = false
		};
	}

	public void function setAccessControlHeaders( routeMethodsMatched ){
		var resp = getPageContext().getResponse();
		var optionsAccessControl = getOptionsAccessControl();
		resp.setHeader( "Access-Control-Allow-Origin", optionsAccessControl.origin );
		resp.setHeader( "Access-Control-Allow-Methods", "OPTIONS," & uCase( structKeyList( routeMethodsMatched ) ) );
		resp.setHeader( "Access-Control-Allow-Headers", optionsAccessControl.headers );
		resp.setHeader( "Access-Control-Allow-Credentials", optionsAccessControl.credentials ? "true" : "false" );
		resp.setHeader( "Access-Control-Max-Age", "#optionsAccessControl.maxAge#" );
	}

	private array function getResourceRoutes(
		any resourcesToRoute,
		string subsystem = '',
		string pathRoot = '',
		string targetAppend = ''
	) {
		var resourceCache = getResourceCache();
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
			setResourceCache(resourceCache);
		}
		return resourceCache[ cacheKey ];
	}

	private struct function processRouteMatch( string route, string target, string path, string httpMethod ) {
		var regExCache = getRegExCache();
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

			if ( !len( routeRegEx.target ) || right( routeRegEx.target, 1) != '/' ){
				routeRegEx.target &= '/';
			}

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
			if (right( routeRegEx.pattern, 1 ) != '$'){
				routeRegEx.pattern &= '(.*)';
			}
			routeRegEx.target &= chr(92) & n;
			regExCache[ cacheKey ] = routeRegEx;
			setRegExCache( regExCache );
		}

		// end of preprocessing section
		var routeMatch = { matched = false };
		structAppend( routeMatch, regExCache[ cacheKey ] );
		if ( !len( path ) || right( path, 1) != '/' ){
			path &= '/'
		};
		if ( routeRegexFind( routeMatch.pattern, path ) ) {
			if ( len( routeMatch.method ) > 1 ) {
				if ( '$' & httpMethod == routeMatch.method ) {
					routeMatch.matched = true;
				} else if ( getPreflightOptions() ) {
					// it matched apart from the method so record this
					request._fw1.routeMethodsMatched[ right( routeMatch.method, len( routeMatch.method ) - 1 ) ] = true;
				}
			} else if ( getPreflightOptions() && httpMethod == "OPTIONS" ) {
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
		if ( getRoutesCaseSensitive() ) {
			return reFind( pattern, path );
		} else {
			return REFindNoCase( pattern, path );
		}
	}
}