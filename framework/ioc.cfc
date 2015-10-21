component {
    variables._fw1_version = "3.5.0";
    variables._di1_version = "1.1.1";
/*
    Copyright (c) 2010-2015, Sean Corfield

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

    // CONSTRUCTOR

    public any function init( any folders, struct config = { } ) {
        variables.folderList = folders;
        variables.folderArray = folders;
        if ( isSimpleValue( folders ) ) {
            variables.folderArray = listToArray( folders );
        } else {
            variables.folderList = arrayToList( folders );
        }
        var n = arrayLen( variables.folderArray );
        for ( var i = 1; i <= n; ++i ) {
            variables.folderArray[ i ] = trim( variables.folderArray[ i ] );
        }
        variables.config = config;
        variables.beanInfo = { };
        variables.beanCache = { };
        variables.resolutionCache = { };
        variables.initMethodCache = { };
        variables.settersInfo = { };
        variables.autoExclude = [
            '/WEB-INF', '/Application.cfc', // never manage these!
            '/Application.lc', '/Application.lucee',
            // assume default name for intermediary:
            '/MyApplication.cfc',
            '/MyApplication.lc', '/MyApplication.lucee',
            'framework.cfc', 'ioc.cfc',     // legacy FW/1 / DI/1
            // recent FW/1 + DI/1 + AOP/1 exclusions:
            '/framework/aop.cfc', '/framework/beanProxy.cfc',
            '/framework/ioc.cfc', '/framework/WireBoxAdapter.cfc',
            '/framework/one.cfc',
            // and Clojure-related exclusions:
            '/framework/cfmljure.cfc', '/framework/cljcontroller.cfc',
            '/framework/ioclj.cfc'
        ];
        variables.listeners = 0;
        setupFrameworkDefaults();
        if ( structKeyExists( variables.config, 'loadListener' ) ) {
            this.onLoad( variables.config.loadListener );
        }
        return this;
    }

    // PUBLIC METHODS

    // programmatically register an alias
    public any function addAlias( string aliasName, string beanName ) {
        discoverBeans();
        variables.beanInfo[ aliasName ] = variables.beanInfo[ beanName ];
        return this;
    }


    // programmatically register new beans with the factory (add a singleton name/value pair)
    public any function addBean( string beanName, any beanValue ) {
        discoverBeans();
        variables.beanInfo[ beanName ] = {
            name = beanName, value = beanValue, isSingleton = true
        };
        return this;
    }


    // return true if the factory (or a parent factory) knows about the requested bean
    public boolean function containsBean( string beanName ) {
        discoverBeans();
        return structKeyExists( variables.beanInfo, beanName ) ||
                ( structKeyExists( variables, 'parent' ) && variables.parent.containsBean( beanName ) );
    }


    // programmatically register new beans with the factory (add an actual CFC)
    public any function declareBean( string beanName, string dottedPath, boolean isSingleton = true, struct overrides = { } ) {
        discoverBeans();
        var singleDir = '';
        if ( listLen( dottedPath, '.' ) > 1 ) {
            var cfc = listLast( dottedPath, '.' );
            var dottedPart = left( dottedPath, len( dottedPath ) - len( cfc ) - 1 );
            singleDir = singular( listLast( dottedPart, '.' ) );
        }
        var basePath = replace( dottedPath, '.', '/', 'all' );
        var cfcPath = expandPath( '/' & basePath & '.cfc' );
        var expPath = cfcPath;
        if ( !fileExists( expPath ) ) expPath = expandPath( '/' & basePath & '.lc' );
        if ( !fileExists( expPath ) ) expPath = expandPath( '/' & basePath & '.lucee' );
        if ( !fileExists( expPath ) ) throw "Unable to find source file for #dottedPath#: expands to #cfcPath#";
        var cfcPath = replace( expPath, chr(92), '/', 'all' );
        var metadata = {
            name = beanName, qualifier = singleDir, isSingleton = isSingleton,
            path = cfcPath, cfc = dottedPath, metadata = cleanMetadata( dottedPath ),
            overrides = overrides
        };
        variables.beanInfo[ beanName ] = metadata;
        return this;
    }

    public any function factoryBean( string beanName, any factory, string methodName, array args = [ ], struct overrides = { } ) {
        discoverBeans();
        var metadata = {
            name = beanName, isSingleton = false, // really?
            factory = factory, method = methodName, args = args,
            overrides = overrides
        };
        variables.beanInfo[ beanName ] = metadata;
        return this;
    }


    // return the requested bean, fully populated
    public any function getBean( string beanName ) {
        discoverBeans();
        if ( structKeyExists( variables.beanInfo, beanName ) ) {
            return resolveBean( beanName );
        } else if ( structKeyExists( variables, 'parent' ) ) {
            return variables.parent.getBean( beanName );
        } else {
            throw 'bean not found: #beanName#';
        }
    }

    // convenience API for metaprogramming perhaps?
    public any function getBeanInfo( string beanName = '', boolean flatten = false,
                                     string regex = '' ) {
        discoverBeans();
        if ( len( beanName ) ) {
            // ask about a specific bean:
            if ( structKeyExists( variables.beanInfo, beanName ) ) {
                return variables.beanInfo[ beanName ];
            }
            if ( structKeyExists( variables, 'parent' ) ) {
                return parentBeanInfo( beanName );
            }
            throw 'bean not found: #beanName#';
        } else {
            var result = { beanInfo = { } };
            if ( structKeyExists( variables, 'parent' ) ) {
                if ( flatten || len( regex ) ) {
                    structAppend( result.beanInfo, parentBeanInfoList( flatten ).beanInfo );
                    structAppend( result.beanInfo, variables.beanInfo );
                } else {
                    result.beanInfo = variables.beanInfo;
                    result.parent = parentBeanInfoList( flatten );
                };
            } else {
                result.beanInfo = variables.beanInfo;
            }
            if ( len( regex ) ) {
                var matched = { };
                for ( var name in result.beanInfo ) {
                    if ( REFind( regex, name ) ) {
                        matched[ name ] = result.beanInfo[ name ];
                    }
                }
                result.beanInfo = matched;
            }
            return result;
        }
    }


    // return a copy of the DI/1 configuration
    public struct function getConfig() {
        // note: we only make a shallow copy
        return structCopy( variables.config );
    }


    // return the DI/1 version
    public string function getVersion() {
        return variables.config.version;
    }


    // return true iff bean is known to be a singleton
    public boolean function isSingleton( string beanName ) {
        discoverBeans();
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
            else bean = construct( bean );
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
        discoverBeans();
        variables.beanCache = { };
        variables.resolutionCache = { };
        variables.initMethodCache = { };
        for ( var key in variables.beanInfo ) {
            if ( !structKeyExists( variables.beanInfo[ key ], "isSingleton" ) )
                throw "internal error: bean #key# has no isSingleton flag!";
            if ( variables.beanInfo[ key ].isSingleton ) {
                getBean( key );
            }
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
                variables.beanCache[ qualifiedName ] = construct( info.cfc );
                newObject = true;
            }
            return { bean = variables.beanCache[ qualifiedName ], newObject = newObject };
        } else {
            return { bean = construct( info.cfc ), newObject = true };
        }
    }


    private struct function cleanMetadata( string cfc ) {
        var baseMetadata = metadata( cfc );
        var iocMeta = { setters = { }, pruned = false, type = baseMetadata.type };
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
                        if ( structKeyExists( property, 'type' ) &&
                             property.type != 'any' ) {
                            iocMeta.setters[ property.name ] = 'typed';
                        } else {
                            iocMeta.setters[ property.name ] = 'implicit';
                        }
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


    // in case an extension point wants to override actual construction:
    private any function construct( string dottedPath ) {
        return createObject( 'component', dottedPath );
    }


    // in case an extension point wants to override actual metadata retrieval:
    private any function metadata( string dottedPath ) {
        try {
            return getComponentMetadata( dottedPath );
        } catch ( any e ) {
            var except = "Unable to getComponentMetadata(#dottedPath#) because: " &
                e.message & ( len( e.detail ) ? " (#e.detail#)" : "" );
            throw except;
        }
    }


    private string function deduceDottedPath( string baseMapping, string basePath ) {
        if ( right( basePath, 1 ) == '/' && len( basePath ) > 1 ) {
            basePath = left( basePath, len( basePath ) - 1 );
        }
        var cfcPath = left( baseMapping, 1 ) == '/' ?
            ( len( baseMapping ) > 1 ? right( baseMapping, len( baseMapping ) - 1 ) : '' ) :
            getFileFromPath( baseMapping );
        if ( right( cfcPath, 1 ) == '/' && len( cfcPath ) > 1 ) {
            cfcPath = left( cfcPath, len( cfcPath ) - 1 );
        }
        var expPath = basePath;
        var notFound = true;
        var dotted = '';
        do {
            var mapped = cfcPath;
            if ( len( mapped ) && left( mapped, 1 ) != '.' ) mapped = '/' & mapped;
            var mappedPath = replace( expandpath( mapped ), chr(92), '/', 'all' );
            if ( mappedPath == basePath ) {
                dotted = replace( cfcPath, '/', '.', 'all' );
                notFound = false;
                break;
            }
            var prevPath = expPath;
            expPath = replace( getDirectoryFromPath( expPath ), chr(92), '/', 'all' );
            if ( right( expPath, 1 ) == '/' && len( expPath ) > 1 ) {
                expPath = left( expPath, len( expPath ) - 1 );
            }
            var progress = prevPath != expPath;
            var piece = listLast( expPath, '/' );
            cfcPath = piece & '/' & cfcPath;
        } while ( progress );
        if ( notFound ) {
            throw 'unable to deduce dot-relative path for: #baseMapping# (#basePath#) root #expandPath("/")#';
        }
        return dotted;
    }


    private void function discoverBeans() {
        if ( structKeyExists( variables, 'discoveryComplete' ) ) return;
        lock name="#application.applicationName#_ioc1_#variables.folderList#" type="exclusive" timeout="30" {
            if ( structKeyExists( variables, 'discoveryComplete' ) ) return;
            variables.pathMapCache = { };
            for ( var f in variables.folderArray ) {
                discoverBeansInFolder( replace( f, chr(92), '/', 'all' ) );
            }
            variables.discoveryComplete = true;
        }
        onLoadEvent();
    }


    private void function discoverBeansInFolder( string mapping ) {
        var folder = replace( expandPath( mapping ), chr(92), '/', 'all' );
        var dotted = deduceDottedPath( mapping, folder );
        var cfcs = [ ];
        try {
            cfcs = directoryList( folder, variables.config.recurse, 'path', '*.cfc' );
            var lcs = directoryList( folder, variables.config.recurse, 'path', '*.lc' );
            for ( var l in lcs ) arrayAppend( cfcs, l );
            lcs = directoryList( folder, variables.config.recurse, 'path', '*.lucee' );
            for ( l in lcs ) arrayAppend( cfcs, l );
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
                    break;
                }
            }
            if ( excludePath ) continue;
            var relPath = right( cfcPath, len( cfcPath ) - len( folder ) );
            var extN = 1 + len( listLast( cfcPath, "." ) );
            relPath = left( relPath, len( relPath ) - extN );
            var dir = listLast( getDirectoryFromPath( cfcPath ), '/' );
            var singleDir = singular( dir );
            var beanName = listLast( relPath, '/' );
            var dottedPath = dotted & replace( relPath, '/', '.', 'all' );
            try {
                var metadata = {
                    name = beanName, qualifier = singleDir, isSingleton = !beanIsTransient( singleDir, dir, beanName ),
                    path = cfcPath, cfc = dottedPath, metadata = cleanMetadata( dottedPath )
                };
                if ( structKeyExists( metadata.metadata, "type" ) && metadata.metadata.type == "interface" ) {
                    continue;
                }
                if ( structKeyExists( variables.beanInfo, beanName ) ) {
                    if ( variables.config.omitDirectoryAliases ) {
                        throw '#beanName# is not unique (and omitDirectoryAliases is true)';
                    }
                    structDelete( variables.beanInfo, beanName );
                    variables.beanInfo[ beanName & singleDir ] = metadata;
                } else {
                    variables.beanInfo[ beanName ] = metadata;
                    if ( !variables.config.omitDirectoryAliases ) {
                        variables.beanInfo[ beanName & singleDir ] = metadata;
                    }
                }
            } catch ( any e ) {
                // wrap the exception so we can add bean name for debugging
                // this trades off any stack trace information for the bean name but
                // since we are only trying to get metadata, the latter should be
                // more useful than the former
                var except = "Problem with metadata for #beanName# (#dottedPath#) because: " &
                    e.message & ( len( e.detail ) ? " (#e.detail#)" : "" );
            }
        }
    }


    private struct function findSetters( any cfc, struct iocMeta ) {
        var liveMeta = { setters = iocMeta.setters };
        if ( !iocMeta.pruned ) {
            // need to prune known setters of transients:
            var prunable = { };
            for ( var known in iocMeta.setters ) {
                if ( !isSingleton( known ) ) {
                    prunable[ known ] = true;
                }
            }
            for ( known in prunable ) {
                structDelete( iocMeta.setters, known );
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
                if ( !structKeyExists( liveMeta.setters, property ) ) {
                    liveMeta.setters[ property ] = 'explicit';
                }
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


    private boolean function isConstant ( string beanName ) {
        return structKeyExists( variables.beanInfo, beanName ) &&
            structKeyExists( variables.beanInfo[ beanName ], 'value' );
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
            if ( isCustomFunction( head.listener ) ||
                 ( listFirst( server.coldfusion.productVersion ) >= 10 &&
                   isClosure( head.listener ) ) ) {
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


    private any function parentBeanInfoList( boolean flatten ) {
        // intended to be adaptable to whatever the parent is:
        if ( structKeyExists( variables.parent, 'getBeanInfo' ) ) {
            // smells like DI/1 or compatible:
            return variables.parent.getBeanInfo( flatten = flatten );
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
        // construction phase:
        var partialBean = resolveBeanCreate( beanName, { injection = { }, dependencies = { } } );
        if ( structKeyExists( variables.resolutionCache, beanName ) &&
             variables.resolutionCache[ beanName ] ) {
            // fully resolved, no action needed this time
        } else {
            var checkForPostInjection = structKeyExists( variables.config, 'initMethod' );
            var initMethod = checkForPostInjection ? variables.config.initMethod : '';
            var postInjectables = { };
            // injection phase:
            // now perform all of the injection:
            for ( var name in partialBean.injection ) {
                var injection = partialBean.injection[ name ];
                if ( checkForPostInjection && !isConstant( name ) && structKeyExists( injection.bean, initMethod ) ) {
                    postInjectables[ name ] = true;
                }
                for ( var property in injection.setters ) {
                    if ( injection.setters[ property ] == 'typed' &&
                        variables.config.omitTypedProperties ) {
                        // we do not inject typed properties!
                        continue;
                    }
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
            // post-injection, pre-init-method phase:
            for ( name in partialBean.injection ) {
                injection = partialBean.injection[ name ];
                setupInitMethod( name, injection.bean );
            }
            // see if anything needs post-injection, init-method calls:
            for ( var postName in postInjectables ) {
                callInitMethod( postName, postInjectables, partialBean, initMethod );
            }
            variables.resolutionCache[ beanName ] = isSingleton( beanName );
        }
        return partialBean.bean;
    }


    private void function callInitMethod( string name, struct injectables, struct info, string method ) {

        if ( injectables[ name ] ) {
            injectables[ name ] = false; // this ensures we don't try to init the same
            // bean twice - and also breaks circular dependencies...
            if ( structKeyExists( info.dependencies, name ) ) {
                for ( var depName in info.dependencies[ name ] ) {
                    if ( structKeyExists( injectables, depName ) &&
                         injectables[ depName ] ) {
                        callInitMethod( depName, injectables, info, method );
                    }
                }
            }
            if ( structKeyExists( variables.initMethodCache, name ) &&
                 variables.initMethodCache[ name ] ) {
            } else {
                variables.initMethodCache[ name ] = isSingleton( name );
                var bean = info.injection[ name ].bean;
                evaluate( 'bean.#method#()' );
            }
        }
    }


    private struct function resolveBeanCreate( string beanName, struct accumulator ) {
        var bean = 0;
        if ( structKeyExists( variables.beanInfo, beanName ) ) {
            var info = variables.beanInfo[ beanName ];
            accumulator.dependencies[ beanName ] = { };
            if ( structKeyExists( info, 'cfc' ) ) {
/*******************************************************/
                var metaBean = cachable( beanName );
                var overrides = structKeyExists( info, 'overrides' ) ? info.overrides : { };
                bean = metaBean.bean;
                if ( metaBean.newObject ) {
                    if ( structKeyExists( info.metadata, 'constructor' ) ) {
                        var args = { };
                        for ( var arg in info.metadata.constructor ) {
                            accumulator.dependencies[ beanName ][ arg ] = true;
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
                        if ( !isNull( __ioc_newBean ) ) {
                            bean = __ioc_newBean;
                            forceCache( bean, beanName );
                        }
                    }
                }
/*******************************************************/
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
                        accumulator.dependencies[ beanName ][ property ] = true;
                        if ( structKeyExists( overrides, property ) ) {
                            // skip resolution because we'll inject override
                        } else {
                            resolveBeanCreate( property, accumulator );
                        }
                    }
                }
                accumulator.bean = bean;
            } else if ( isConstant( beanName ) ) {
                accumulator.bean = info.value;
                accumulator.injection[ beanName ] = { bean = info.value, setters = { } };
            } else if ( structKeyExists( info, 'factory' ) ) {
                var fmBean = isSimpleValue( info.factory ) ? this.getBean( info.factory ) : info.factory;
                var nArgs = arrayLen( info.args );
                var argStruct = { };
                for ( var i = 1; i <= nArgs; ++i ) {
                    var argName = info.args[ i ];
                    if ( structKeyExists( info.overrides, argName ) ) {
                        argStruct[ i ] = info.overrides[ argName ];
                    } else {
                        argStruct[ i ] = this.getBean( argName );
                    }
                }
                accumulator.bean = evaluate( 'fmBean.#info.method#(argumentCollection=argStruct)' );
                accumulator.injection[ beanName ] = { bean = accumulator.bean, setters = { } };
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
        param name = "variables.config.recurse"     default = true;
        param name = "variables.config.strict"      default = false;

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

        if ( !structKeyExists( variables.config, 'omitTypedProperties' ) ) {
            variables.config.omitTypedProperties = false;
        }
        if ( !structKeyExists( variables.config, 'omitDirectoryAliases' ) ) {
            variables.config.omitDirectoryAliases = false;
        }
        if ( !structKeyExists( variables.config, 'singulars' ) ) {
            variables.config.singulars = { };
        }
        if ( !structKeyExists( variables.config, 'liberal' ) ) {
            variables.config.liberal = false;
        }

        variables.config.version = variables._di1_version;
    }


    // hook for extension points to process beans after they have been
    // constructed and injected, but before init-method is called on anything
    private void function setupInitMethod( string name, any bean ) {
    }


    private string function singular( string plural ) {
        if ( structKeyExists( variables.config.singulars, plural ) ) {
            return variables.config.singulars[ plural ];
        }
        var single = plural;
        var n = len( plural );
        var last = right( plural, 1 );
        if ( last == 's' ) {
            if ( variables.config.liberal && n > 3 && right( plural, 3 ) == 'ies' ) {
                single = left( plural, n - 3 ) & 'y';
            } else {
                single = left( plural, n - 1 );
            }
        }
        return single;
    }

}
