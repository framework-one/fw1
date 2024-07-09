component {
    variables._fw1_version = "4.3.2";
    variables._di1_version = variables._fw1_version;
    
    /*
        Copyright (c) 2010-2018, Sean Corfield

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

    /**
     * Initializes the Inversion of Control (IoC) container.
     *
     * @folders any                     A list of folders to scan for beans.
     * @config struct                   The configuration settings for the IoC container. (optional)
     * 
     * @return any                      The current instance of the `ioc` component.
     */
    public any function init( 
        any folders, 
        struct config = { } 
    ) {
        variables.folderList = folders;
        variables.folderArray = folders;
        if ( isSimpleValue( folders ) ) {
            variables.folderArray = listToArray( folders );
        } else {
            variables.folderList = arrayToList( folders );
        }
        var n = arrayLen( variables.folderArray );
        for ( var i = 1; i <= n; ++i ) {
            var folderName = trim( variables.folderArray[ i ] );
            // strip trailing slash since it can cause weirdness in path
            // deduction on some engines on some platforms (guess which!)
            if ( len( folderName ) > 1 &&
                    ( right( folderName, 1 ) == '/' ||
                    right( folderName, 1 ) == chr(92) ) ) {
                folderName = left( folderName, len( folderName ) - 1 );
            }
            variables.folderArray[ i ] = folderName;
        }
        variables.config = config;
        variables.beanInfo = { };
        variables.beanCache = { };
        variables.resolutionCache = { };
        variables.getBeanCache = { };
        variables.accumulatorCache = { };
        variables.initMethodCache = { };
        variables.settersInfo = { };
        variables.autoExclude = [
            '/WEB-INF', '/Application.cfc', // never manage these!
            // assume default name for intermediary:
            '/MyApplication.cfc',
            'framework.cfc', 'ioc.cfc',     // legacy FW/1 / DI/1
            // recent FW/1 + DI/1 + AOP/1 exclusions:
            '/framework/aop.cfc', '/framework/beanProxy.cfc',
            '/framework/ioc.cfc', '/framework/WireBoxAdapter.cfc',
            '/framework/one.cfc'
        ];
        variables.listeners = 0;
        setupFrameworkDefaults();
        if ( structKeyExists( variables.config, 'loadListener' ) ) {
            this.onLoad( variables.config.loadListener );
        }
        return this;
    }

    // PUBLIC METHODS

    /**
     * Adds an alias for a bean.
     *
     * @aliasName string                The name of the alias.
     * @beanName string                 The name of the bean to create an alias for.
     * 
     * @return any                      The current instance of the `ioc` component.
     */
    public any function addAlias( 
        string aliasName, 
        string beanName 
    ) {
        discoverBeans(); // still need this since we rely on beanName having been discovered :(
        variables.beanInfo[ aliasName ] = variables.beanInfo[ beanName ];
        return this;
    }


    /**
     * Programmatically register a new bean with the factory.
     *
     * @beanName string                     The name of the bean to register.
     * @beanValue any                       The value of the bean to register.
     * 
     * @return any                          The bean factory.
     */
    public any function addBean( 
        string beanName, 
        any beanValue 
    ) {
        variables.beanInfo[ beanName ] = {
            name = beanName, value = beanValue, isSingleton = true
        };
        return this;
    }


    /**
     * Determines if the factory (or a parent factory) knows about the requested bean.
     *
     * @beanName string                     The name of the bean to check.
     * 
     * @return boolean                      Returns true if the factory (or a parent factory) knows about the requested bean, otherwise returns false.
     */
    public boolean function containsBean( 
        string beanName 
    ) {
        discoverBeans();
        return structKeyExists( variables.beanInfo, beanName ) ||
            ( hasParent() && variables.parent.containsBean( beanName ) );
    }


    /**
     * This function is used to declare a bean in the Inversion of Control (IoC) container.
     * It returns a declaration object that allows for method chaining to configure the bean.
     *
     * @beanName string                     The name of the bean to be declared.
     * 
     * @return any                          The declaration object for the bean.
     * 
     * @throws                              An exception if the declaration builder is already completed.
     */
    public any function declare( 
        string beanName 
    ) {
        var declaration = { beanName : beanName, built : false };
        var beanFactory = this; // to make the builder functions less confusing
        structAppend( declaration, {
            // builder for addAlias()
            aliasFor : function( string beanName ) {
                if ( declaration.built ) throw "Declaration builder already completed!";
                declaration.built = true;
                beanFactory.addAlias( declaration.beanName, beanName );
                return declaration;
            },
            // builder for addBean()
            asValue : function( any beanValue ) {
                if ( declaration.built ) throw "Declaration builder already completed!";
                declaration.built = true;
                beanFactory.addBean( declaration.beanName, beanValue );
                return declaration;
            },
            // builder for factoryBean()
            fromFactory : function( any factory, string methodName = "" ) {
                if ( declaration.built ) throw "Declaration builder already completed!";
                declaration.built = true;
                // use defaults -- we can override later
                beanFactory.factoryBean( declaration.beanName, factory, methodName );
                return declaration;
            },
            // builder for declareBean()
            instanceOf : function( string dottedPath ) {
                if ( declaration.built ) throw "Declaration builder already completed!";
                declaration.built = true;
                // use defaults -- we can override later
                beanFactory.declareBean( declaration.beanName, dottedPath );
                return declaration;
            },
            // modifiers for metadata
            asSingleton : function() {
                if ( !declaration.built ) throw "No declaration builder to modify!";
                variables.beanInfo[ declaration.beanName ].isSingleton = true;
                return declaration;
            },
            asTransient : function() {
                if ( !declaration.built ) throw "No declaration builder to modify!";
                variables.beanInfo[ declaration.beanName ].isSingleton = false;
                return declaration;
            },
            withArguments : function( array args ) {
                if ( !declaration.built ) throw "No declaration builder to modify!";
                var info = variables.beanInfo[ declaration.beanName ];
                if ( !structKeyExists( info, 'factory' ) ) throw "withArguments() requires fromFactory()!";
                info.args = args;
                return declaration;
            },
            withOverrides : function( struct overrides ) {
                if ( !declaration.built ) throw "No declaration builder to modify!";
                var info = variables.beanInfo[ declaration.beanName ];
                if ( !structKeyExists( info, 'factory' ) &&
                    !structKeyExists( info, 'cfc' ) ) throw "withOverrides() requires fromFactory() or instanceOf()!";
                info.overrides = overrides;
                return declaration;
            },
            // to allow chaining
            done : function() {
                return beanFactory;
            }
        } );
        return declaration;
    }

    
    /**
     * Programmatically register a new bean with the factory.
     *
     * @beanName string                     The name of the bean to register.
     * @dottedPath string                   The dotted path to the CFC to register.
     * @isSingleton boolean                 Whether the bean is a singleton or not. (optional)
     * @overrides struct                    The overrides to apply to the bean. (optional)
     * 
     * @return any                          The bean factory.
     */
    public any function declareBean( 
        string beanName, 
        string dottedPath, 
        boolean isSingleton = true, 
        struct overrides = { } 
    ) {
        var singleDir = '';
        if ( listLen( dottedPath, '.' ) > 1 ) {
            var cfc = listLast( dottedPath, '.' );
            var dottedPart = left( dottedPath, len( dottedPath ) - len( cfc ) - 1 );
            singleDir = singular( listLast( dottedPart, '.' ) );
        }
        var basePath = replace( dottedPath, '.', '/', 'all' );
        var cfcPath = expandPath( '/' & basePath & '.cfc' );
        var expPath = cfcPath;
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

    /**
     * Programmatically register a factory bean with the factory.
     *
     * @beanName string             The name of the bean to register.
     * @factory any                 The factory object to use to create the bean.
     * @methodName string           The name of the method to call on the factory object to create the bean. (optional)
     * @args array                  The arguments to pass to the factory method. (optional)
     * @overrides struct            The overrides to apply to the bean. (optional)
     * 
     * @return any                  The bean factory.
     */
    public any function factoryBean( 
        string beanName, 
        any factory, 
        string methodName = "", 
        array args = [ ], 
        struct overrides = { } 
    ) {
        var metadata = {
            name = beanName, isSingleton = false, // really?
            factory = factory, method = methodName, args = args,
            overrides = overrides
        };
        variables.beanInfo[ beanName ] = metadata;
        return this;
    }


    /**
     * Retrieves a bean from the factory, fully populated.
     *
     * @beanName string             The name of the bean to retrieve.
     * @constructorArgs struct      The arguments to pass to the bean's constructor. (optional)
     * 
     * @return any                  The bean.
     */
    public any function getBean( 
        string beanName, 
        struct constructorArgs = { } 
    ) {
        discoverBeans();
        if ( structKeyExists( variables.beanInfo, beanName ) ) {
            if ( structKeyExists( variables.getBeanCache, beanName ) ) {
                return variables.getBeanCache[ beanName ];
            }
            var bean = resolveBean( beanName, constructorArgs );
            if ( isSingleton( beanName ) ) variables.getBeanCache[ beanName ] = bean;
            return bean;
        } else if ( hasParent() ) {
            // ideally throw an exception for non-DI/1 parent when args passed
            // WireBox adapter can do that since we control it but we can't do
            // anything for other bean factories - will revisit before release
            return variables.parent.getBean( beanName, constructorArgs );
        } else {
            return missingBean( beanName = beanName, dependency = false );
        }
    }

    /**
     * Retrieves information about one or more beans.
     * 
     * @beanName string             The name of the bean to retrieve information for. (optional)
     * @flatten boolean             Determines whether to flatten the bean information from the parent beans. (optional)
     * @regex strging               A regular expression to filter the bean names. (optional)
     * 
     * @return struct               The bean information as a struct.
     * 
     * @throws                      An exception if the bean is not found.
     * 
     * @example
     * var beanInfo = getBeanInfo("myBean"); // retrieve information for the bean named "myBean"
     * 
     * @example
     * var allBeanInfo = getBeanInfo(); // retrieve information for all beans, including parent beans
     * 
     * @example
     * var filteredBeanInfo = getBeanInfo("", false, ".*Controller"); // retrieve information for all beans matching a regular expression
     */
    public any function getBeanInfo( 
        string beanName = '', 
        boolean flatten = false,
        string regex = '' 
    ) {
        discoverBeans();
        if ( len( beanName ) ) {
            // ask about a specific bean:
            if ( structKeyExists( variables.beanInfo, beanName ) ) {
                return variables.beanInfo[ beanName ];
            }
            if ( hasParent() ) {
                return parentBeanInfo( beanName );
            }
            throw 'bean not found: #beanName#';
        } else {
            var result = { beanInfo = { } };
            if ( hasParent() ) {
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


    // return true if this factory has a parent
    public boolean function hasParent() {
        return structKeyExists( variables, 'parent' );
    }


    // return true if bean is known to be a singleton
    public boolean function isSingleton(
        string beanName 
    ) {
        discoverBeans();
        if ( structKeyExists( variables.beanInfo, beanName ) ) {
            return variables.beanInfo[ beanName ].isSingleton;
        } else if ( hasParent() ) {
            try {
                return variables.parent.isSingleton( beanName );
            } catch ( any e ) {
                return false; // parent doesn't know the bean therefore is it not singleton
            }
        } else {
            return false; // we don't know the bean therefore it is not a managed singleton
        }
    }


    /*
    * @hint Given a bean (by name, by type or by value), call the named setters with the specified property values
    * @ignoreMissing When set verify that the setter to be called exists and skip if missing, otherwise throws an error
    */
    public any function injectProperties( 
        any bean, 
        struct properties, 
        boolean ignoreMissing=false 
    ) {
        if ( isSimpleValue( bean ) ) {
            if ( containsBean( bean ) ) bean = getBean( bean );
            else bean = construct( bean );
        }
        for ( var property in properties ) {
            if ( !isNull( properties[ property ] ) && (!ignoreMissing || structKeyExists( bean, "set#property#" ) ) ){
                var args = { };
                args[ property ] = properties[ property ];
                invoke( bean, "set#property#", args );
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
        variables.accumulatorCache = { };
        variables.getBeanCache = { };
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
    public any function onLoad( 
        any listener 
    ) {
        var head = { next = variables.listeners, listener = listener };
        variables.listeners = head;
        return this;
    }


    // set the parent bean factory
    public any function setParent( 
        any parent 
    ) {
        variables.parent = parent;
        return this;
    }

    // PRIVATE METHODS

    /**
     * Determines if a bean is transient based on the provided parameters.
     *
     * @singleDir string                    The single directory.
     * @dir string                          The directory.
     * @beanName string                     The name of the bean.
     *
     * @return boolean                      Returns true if the bean is transient, otherwise returns false.
     */
    private boolean function beanIsTransient( 
        string singleDir, 
        string dir, 
        string beanName 
    ) {
        return singleDir == 'bean' ||
            structKeyExists( variables.transients, dir ) ||
            ( structKeyExists( variables.config, "singletonPattern" ) &&
                refindNoCase( variables.config.singletonPattern, beanName ) == 0 ) ||
            ( structKeyExists( variables.config, "transientPattern" ) &&
                refindNoCase( variables.config.transientPattern, beanName ) > 0 );
    }


    /**
     * This private function checks if a bean is cachable and returns the bean object.
     * 
     * @beanName string                     The name of the bean to check.
     * 
     * @return struct                       A struct containing the bean object and a flag indicating if a new object was created.
     */
    private any function cachable( 
        string beanName 
    ) {
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


    /**
     * Cleans the metadata of a CFC.
     * 
     * @cfc string                      The path of the CFC.
     * 
     * @return struct                   The cleaned metadata of the CFC.
     */
    private struct function cleanMetadata( 
        string cfc 
    ) {
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
                            property.type != 'any' &&
                            variables.config.omitTypedProperties ) {
                            iocMeta.setters[ property.name ] = 'ignored';
                        } else if ( structKeyExists( property, 'default' ) &&
                                    variables.config.omitDefaultedProperties ) {
                            iocMeta.setters[ property.name ] = 'ignored';
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
    private any function construct( 
        string dottedPath 
    ) {
        return createObject( 'component', dottedPath );
    }


    // in case an extension point wants to override actual metadata retrieval:
    private any function metadata( 
        string dottedPath 
    ) {
        try {
            return getComponentMetadata( dottedPath );
        } catch ( any e ) {
            var except = "Unable to getComponentMetadata(#dottedPath#) because: " &
                e.message & ( len( e.detail ) ? " (#e.detail#)" : "" );
            try {
                except = except & ", near line " & e.tagContext[1].line &
                    " in " & e.tagContext[1].template;
            } catch ( any e ) {
                // unable to determine template / line number so just use
                // the exception message we built so far
            }
            throw except;
        }
    }


    /**
     * This private function is used to deduce the dot-relative path for a given base mapping and base path.
     * 
     * @baseMapping string              The base mapping to deduce the dot-relative path for.
     * @basePath string                 The base path to deduce the dot-relative path for.
     * 
     * @return                          The dot-relative path deduced from the base mapping and base path.
     * 
     * @throws                          An exception if the dot-relative path cannot be deduced.
     */
    private string function deduceDottedPath( 
        string baseMapping, 
        string basePath 
    ) {
        // Remove trailing slash from basePath if it exists
        if ( right( basePath, 1 ) == '/' && len( basePath ) > 1 ) {
            basePath = left( basePath, len( basePath ) - 1 );
        }
        
        // Get the CFC path from the baseMapping
        var cfcPath = left( baseMapping, 1 ) == '/' ?
            ( len( baseMapping ) > 1 ? right( baseMapping, len( baseMapping ) - 1 ) : '' ) :
            getFileFromPath( baseMapping );
        
        // Remove trailing slash from cfcPath if it exists
        if ( right( cfcPath, 1 ) == '/' && len( cfcPath ) > 1 ) {
            cfcPath = left( cfcPath, len( cfcPath ) - 1 );
        }
        
        var expPath = basePath;
        var notFound = true;
        var dotted = '';
        
        // Loop until the dot-relative path is found or not found
        do {
            var mapped = cfcPath;
            
            // Prepend '/' to mapped if it doesn't start with '.'
            if ( len( mapped ) && left( mapped, 1 ) != '.' ) {
                mapped = '/' & mapped;
            }
            
            // Convert mapped path to a URL-style path
            var mappedPath = replace( expandpath( mapped ), chr(92), '/', 'all' );
            
            // Check if mappedPath matches basePath
            if ( mappedPath == basePath ) {
                // Convert cfcPath to dot-relative path
                dotted = replace( cfcPath, '/', '.', 'all' );
                notFound = false;
                break;
            }
            
            var prevPath = expPath;
            
            // Get the parent directory of expPath
            expPath = replace( getDirectoryFromPath( expPath ), chr(92), '/', 'all' );
            
            // Remove trailing slash from expPath if it exists
            if ( right( expPath, 1 ) == '/' && len( expPath ) > 1 ) {
                expPath = left( expPath, len( expPath ) - 1 );
            }
            
            // Check if progress is made in finding the dot-relative path
            var progress = prevPath != expPath;
            
            // Continue the loop until the dot-relative path is found or not found
        } while ( progress && notFound );
        
        // Return the dot-relative path
        return dotted;
    }
            var piece = listLast( expPath, '/' );
            cfcPath = piece & '/' & cfcPath;
        } while ( progress );
        if ( notFound ) {
            throw 'unable to deduce dot-relative path for: #baseMapping# (#basePath#) root #expandPath("/")#';
        }
        return dotted;
    }


    /**
     * This private function is responsible for discovering beans in the framework's IOC component.
     * It checks if the discovery process has already been completed and if so, it returns immediately.
     * Otherwise, it locks the execution to ensure exclusive access and proceeds with the discovery process.
     * 
     * The function starts by initializing the pathMapCache variable as an empty struct.
     * It then iterates over each folder in the folderArray variable and calls the discoverBeansInFolder function
     * to discover beans in that folder.
     * 
     * After the discovery process is complete, the discoveryComplete variable is set to true to indicate that
     * the discovery process has been completed.
     * 
     * Finally, the onLoadEvent function is called.
     * 
     * @return void
     */
    private void function discoverBeans() {
        if ( structKeyExists( variables, 'discoveryComplete' ) ) return;
        lock name="#application.applicationName#_ioc1_#variables.folderList#" type="exclusive" timeout="30" {
            if ( structKeyExists( variables, 'discoveryComplete' ) ) return;
            variables.pathMapCache = { };
            try {
                for ( var f in variables.folderArray ) {
                    discoverBeansInFolder( replace( f, chr(92), '/', 'all' ) );
                }
            } finally {
                variables.discoveryComplete = true;
            }
        }
        onLoadEvent();
    }


    /**
     * This private function is responsible for discovering beans in a specified folder.
     * 
     * @mapping string The folder path to search for CFC files.
     * 
     * @return void
     * 
     * @throws Exception Throws an exception if there is a problem with the metadata for a bean.
     */
    private void function discoverBeansInFolder( 
        string mapping 
    ) {
        var folder = replace( expandPath( mapping ), chr(92), '/', 'all' );
        var dotted = deduceDottedPath( mapping, folder );
        var cfcs = [ ];
        try {
            cfcs = directoryList( folder, variables.config.recurse, 'path', '*.cfc' );
        } catch ( any e ) {
            throw( message="Error while discovering beans in folder: #folder#", detail="Exception: #e.message#", beanName="", cfcPath="" );
        }
        local.beansWithDuplicates = "";
        for ( var cfcOSPath in cfcs ) {
            try {
                var cfcPath = replace( cfcOSPath, chr(92), '/', 'all' );
                var beanName = getBeanNameFromPath( cfcPath );
                var qualifier = getQualifierFromPath( cfcPath );
                var isSingleton = isSingletonBean( cfcPath );
                var isInterface = isInterfaceBean( cfcPath );
                var path = replace( cfcPath, folder, '', 'all' );
                var beanPath = dotted & '.' & beanName;
                
                if (isInterface) {
                    continue;
                }
                
                if (variables.config.omitDirectoryAliases) {
                    if (isDuplicateBean(beanName)) {
                        throw( message="Duplicate bean name found: #beanName#", detail="Bean path: #beanPath#", beanName=beanName, cfcPath=cfcPath );
                    }
                } else {
                    handleDuplicateBean(beanName, beanPath);
                }
                
                var metadata = {
                    beanName = beanName,
                    qualifier = qualifier,
                    isSingleton = isSingleton,
                    path = path,
                    cfcPath = cfcPath
                };
                
                variables.beanInfo[beanName] = metadata;
            } catch ( any e ) {
                throw( message="Error while processing bean: #beanName#", detail="Exception: #e.message#", beanName=beanName, cfcPath=cfcPath );
            }
        }
    }

    
    /**
     * This private function is responsible for discovering beans in a specified folder.
     * 
     * @mapping string                      The mapping of the folder where the beans are located.
     * 
     * @return void
     */
    private void function discoverBeansInFolder( 
        string mapping 
    ) {
        var folder = replace( expandPath( mapping ), chr(92), '/', 'all' );
        var dotted = deduceDottedPath( mapping, folder );
        var cfcs = [ ];
        try {
            cfcs = directoryList( folder, variables.config.recurse, 'path', '*.cfc' );
        } catch ( any e ) {
            // assume bad path - ignore it, cfcs is empty list
        }
        local.beansWithDuplicates = "";
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

                if ( variables.config.omitDirectoryAliases ) {
                    if ( structKeyExists( variables.beanInfo, beanName ) ) {
                        throw '#beanName# is not unique';
                    }
                    variables.beanInfo[ beanName ] = metadata;
                } else {
                    if ( listFindNoCase(local.beansWithDuplicates, beanName) ) {}
                    else if ( structKeyExists( variables.beanInfo, beanName ) ) {
                        structDelete( variables.beanInfo, beanName );
                        local.beansWithDuplicates = listAppend(local.beansWithDuplicates, beanName);
                    } else {
                        variables.beanInfo[ beanName ] = metadata;
                    }
                    if ( structKeyExists( variables.beanInfo, beanName & singleDir ) ) {
                        throw '#beanName & singleDir# is not unique';
                    }
                    variables.beanInfo[ beanName & singleDir ] = metadata;
                }

            } catch ( any e ) {
                // wrap the exception so we can add bean name for debugging
                // this trades off any stack trace information for the bean name but
                // since we are only trying to get metadata, the latter should be
                // more useful than the former
                var except = "Problem with metadata for #beanName# (#dottedPath#) because: " &
                    e.message & ( len( e.detail ) ? " (#e.detail#)" : "" );
                throw except;
            }
        }
    }


    /**
     * Private function used to find the setters of a CFC and return them in a struct.
     * 
     * @cfc any                         The CFC for which to find the setters.
     * @iocMeta struct                  The IOC (Inversion of Control) metadata struct.
     * 
     * @return struct                   The struct containing the found setters.
     */
    private struct function findSetters( 
        any cfc, 
        struct iocMeta 
    ) {
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


    /**
     * Private function that forces caching of a bean.
     * 
     * @bean any                    The bean object to be cached.
     * @beanName string             The name of the bean.
     * 
     * @return void 
     */
    private void function forceCache( 
        any bean, 
        string beanName 
    ) {
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


    /**
     * Checks if a bean is a constant.
     * 
     * @beanName string             The name of the bean to check.
     * 
     * @return boolean              Returns a boolean value indicating whether the bean is a constant.
     */
    private boolean function isConstant ( 
        string beanName 
    ) {
        return structKeyExists( variables.beanInfo, beanName ) &&
            structKeyExists( variables.beanInfo[ beanName ], 'value' );
    }


    /**
     * Logs a message about a missing bean.
     *
     * @beanName string                 The name of the missing bean.
     * @resolvingBeanName string        The name of the bean that is currently being resolved (optional).
     * 
     * @return void
     */
    private void function logMissingBean( 
        string beanName, 
        string resolvingBeanName = '' 
    ) {
        var sys = createObject( 'java', 'java.lang.System' );
        if ( len( resolvingBeanName ) ) {
            sys.out.println( 'bean not found: #beanName#; while resolving #resolvingBeanName#' );
        } else {
            sys.out.println( 'bean not found: #beanName#' );
        }
    }

    
    /**
     * Handles missing beans in the Inversion of Control (IoC) container.
     * Override this method to provide custom handling of missing beans.
     * 
     * @beanName string                     The name of the missing bean.
     * @resolvingBeanName string            The name of the bean that is currently being resolved (optional).
     * @dependency boolean                  A flag indicating whether the missing bean is a dependency (optional).
     * 
     * @return void
     * 
     * @throws                              Throws an exception if the missing bean is not found and the container is in strict mode or if the missing bean is a dependency.
     */
    private any function missingBean( 
        string beanName, 
        string resolvingBeanName = '', 
        boolean dependency = true 
    ) {
        if ( variables.config.strict || !dependency ) {
            if ( len( resolvingBeanName ) ) {
                throw 'bean not found: #beanName#; while resolving #resolvingBeanName#';
            } else {
                throw 'bean not found: #beanName#';
            }
        } else {
            logMissingBean( beanName, resolvingBeanName );
        }
    }


    /**
     * Executes the onLoad event by invoking all registered listeners.
     * 
     * @return void
     */
    private void function onLoadEvent() {
        var head = variables.listeners;
        while ( isStruct( head ) ) {
            if ( isCustomFunction( head.listener ) || isClosure( head.listener ) ) {
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


    /**
     * Retrieves the bean information for the parent bean with the specified name.
     * This method is intended to be adaptable to different parent bean frameworks.
     * 
     * @beanName string                 The name of the parent bean.
     * 
     * @return any                      The bean information for the parent bean, or an empty struct if the parent is unknown.
     */
    private any function parentBeanInfo( 
        string beanName 
    ) {
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


    /**
     * Retrieve the parent bean information list.
     *
     * @flatten boolean             Determines whether to flatten the bean information from the parent beans.
     * 
     * @return any                  The parent bean information list.
     */
    private any function parentBeanInfoList( 
        boolean flatten 
    ) {
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


    /**
     * Resolve a bean, creating and initializing it as necessary.
     *
     * @beanName string             The name of the bean to resolve.
     * @constructorArgs struct      The arguments to pass to the bean's constructor. (optional)
     * 
     * @return any                  The resolved bean.
     */
    private any function resolveBean( 
        string beanName, 
        struct constructorArgs = { } 
    ) {
        // do enough resolution to create and initialization this bean
        // returns a struct of the bean and a struct of beans and setters still to run
        // construction phase:
        var accumulator = { injection = { } };
        // ensure only injection singletons end up cached in variables scope
        if ( structKeyExists( variables.accumulatorCache, beanName ) ) {
            structAppend( accumulator.injection, variables.accumulatorCache[ beanName ].injection );
        } else {
            variables.accumulatorCache[ beanName ] = { injection = { }, dependencies = { } };
        }
        // all dependencies can be cached in variables scope
        accumulator.dependencies = variables.accumulatorCache[ beanName ].dependencies;
        var partialBean = resolveBeanCreate( beanName, accumulator, constructorArgs );
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
                if ( structKeyExists( variables.accumulatorCache[ beanName ].injection, name ) ) {
                    // this singleton is in the accumulatorCache, thus it has already been fully resolved
                    continue;
                }
                var injection = partialBean.injection[ name ];
                if ( checkForPostInjection && !isConstant( name ) && structKeyExists( injection.bean, initMethod ) ) {
                    postInjectables[ name ] = true;
                }
                for ( var property in injection.setters ) {
                    if ( injection.setters[ property ] == 'ignored' ) {
                        // do not inject defaulted/typed properties!
                        continue;
                    }
                    var args = { };
                    if ( structKeyExists( injection.overrides, property ) ) {
                        args[ property ] = injection.overrides[ property ];
                    } else if ( structKeyExists( partialBean.injection, property ) ) {
                        args[ property ] = partialBean.injection[ property ].bean;
                    } else if ( hasParent() && variables.parent.containsBean( property ) ) {
                        args[ property ] = variables.parent.getBean( property );
                    } else {
                        // allow for possible convention-based bean factory
                        args[ property ] = missingBean( property, beanName );
                        // isNull() does not always work on ACF10...
                        try { if ( isNull( args[ property ] ) ) continue; } catch ( any e ) { continue; }
                    }
                    invoke( injection.bean, "set#property#", args );
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
            for ( name in partialBean.injection ) {
                if ( isSingleton( name ) ) {
                    variables.accumulatorCache[ beanName ].injection[ name ] = partialBean.injection[ name ];
                }
            }
            variables.resolutionCache[ beanName ] = isSingleton( beanName );
        }
        return partialBean.bean;
    }

    
    /**
     * Calls the initialization method for a bean.
     * 
     * @name string                     The name of the bean.
     * @injectables struct              A struct containing the injectable beans.
     * @info struct                     A struct containing information about the beans.
     * @method string                   The name of the initialization method to call.
     * 
     * @return void
     */
    private void function callInitMethod( 
        string name, 
        struct injectables, 
        struct info, 
        string method 
    ) {

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
                invoke( bean, method );
            }
        }
    }


    /**
     * Resolve a bean, creating and initializing it as necessary.
     *
     * @beanName string                     The name of the bean to resolve.
     * @accumulator struct                  The accumulator for the resolution process.
     * @constructorArgs struct              The arguments to pass to the bean's constructor. (optional)
     * 
     * @return struct                       The resolved bean.
     */
    private struct function resolveBeanCreate( 
        string beanName, 
        struct accumulator, 
        struct constructorArgs = { } 
    ) {
        var bean = 0;
        if ( structKeyExists( variables.beanInfo, beanName ) ) {
            var info = variables.beanInfo[ beanName ];
            if ( !structKeyExists( accumulator.dependencies, beanName ) ) accumulator.dependencies[ beanName ] = { };
            if ( structKeyExists( info, 'cfc' ) ) {
/*******************************************************/
                var metaBean = cachable( beanName );
                var overrides = { };
                // be careful not to modify overrides metadata:
                if ( structCount( constructorArgs ) ) {
                    if ( structKeyExists( info, 'overrides' ) ) {
                        structAppend( overrides, info.overrides );
                    }
                    structAppend( overrides, constructorArgs );
                } else {
                    if ( structKeyExists( info, 'overrides' ) ) {
                        overrides = info.overrides;
                    }
                }
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
                        var __ioc_newBean = bean.init( argumentCollection = args );
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
            } else if ( isConstant( beanName ) ) {
                bean = info.value;
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
                if ( isCustomFunction( fmBean ) || isClosure( fmBean ) ) {
                    bean = fmBean( argumentCollection = argStruct );
                } else {
                    bean = invoke( fmBean, "#info.method#", argStruct );
                }
                accumulator.injection[ beanName ] = { bean = bean, setters = { } };
            } else {
                throw 'internal error: invalid metadata for #beanName#';
            }
        } else {
            if ( hasParent() && variables.parent.containsBean( beanName ) ) {
                bean = variables.parent.getBean( beanName );
            } else {
                bean = missingBean( beanName = beanName, dependency = true );
            }
            if ( !isNull( bean ) ) {
                accumulator.injection[ beanName ] = { bean = bean, setters = { } };
            }
        }
        return {
            bean = bean,
            injection = accumulator.injection,
            dependencies = accumulator.dependencies
        };
    }



    /** 
     * Sets up the default configuration for the framework.
     * This function initializes various configuration settings and constants used by the framework.
     * It also sets up the bean factory and handles exclusion and transient folders.
     * 
     * @return void
     */ 
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

        if ( !structKeyExists( variables.config, 'omitDefaultedProperties' ) ) {
            variables.config.omitDefaultedProperties = true;
        }
        if ( !structKeyExists( variables.config, 'omitTypedProperties' ) ) {
            variables.config.omitTypedProperties = true;
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


    /**
     * This private function is responsible for processing beans after they have been constructed and injected,
     * but before the init-method is called on anything.
     * 
     * @return void
     */
    private void function setupInitMethod( 
        string name, 
        any bean 
    ) { }


    /**
     * Given a plural word, return the singular form.
     *
     * @plural string               The plural word to convert.
     * 
     * @return string               The singular form of the word.
     */
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
