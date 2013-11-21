component extends="tests.InjectableTest" {

    public void function setUp() {
        variables.fw = new org.corfield.framework();
        injectMethod( variables.fw, this, 'isFrameworkInitialized', 'isFrameworkInitialized' );
        variables.fwVars = getVariablesScope( variables.fw );
        variables.fw.getResourceRoutes = variables.fwVars.getResourceRoutes;
        variables.fwVars.framework.resourceRouteTemplates = [
            { method = 'default', httpMethods = [ '$GET' ] },
            { method = 'new', httpMethods = [ '$GET' ], routeSuffix = '/new' },
            { method = 'create', httpMethods = [ '$POST' ] },
            { method = 'show', httpMethods = [ '$GET' ], includeId = true },
            { method = 'update', httpMethods = [ '$PUT','$PATCH' ], includeId = true },
            { method = 'destroy', httpMethods = [ '$DELETE' ], includeId = true }
        ];
        variables.fwVars.framework.subsystemDelimiter = ':';
   }

    public void function testResourceBasics() {

        var routesViaString = variables.fw.getResourceRoutes( 'dogs,cats' );
        var routesViaArray = variables.fw.getResourceRoutes( [ 'dogs','cats' ] );        
        var routesViaStruct = variables.fw.getResourceRoutes( { resources = 'dogs,cats' } );        

        var expectedRoutes = [
            { '$GET/dogs/$' = '/dogs/default' },
            { '$GET/dogs/new/$' = '/dogs/new' },
            { '$POST/dogs/$' = '/dogs/create' },
            { '$GET/dogs/:id/$' = '/dogs/show/id/:id' },
            { '$PATCH/dogs/:id/$' = '/dogs/update/id/:id', '$PUT/dogs/:id/$' = '/dogs/update/id/:id' },
            { '$DELETE/dogs/:id/$' = '/dogs/destroy/id/:id' },
            { '$GET/cats/$' = '/cats/default' },
            { '$GET/cats/new/$' = '/cats/new' },
            { '$POST/cats/$' = '/cats/create' },
            { '$GET/cats/:id/$' = '/cats/show/id/:id' },
            { '$PATCH/cats/:id/$' = '/cats/update/id/:id', '$PUT/cats/:id/$' = '/cats/update/id/:id' },
            { '$DELETE/cats/:id/$' = '/cats/destroy/id/:id' }
        ];

        assertEquals( expectedRoutes, routesViaString );
        assertEquals( expectedRoutes, routesViaArray );
        assertEquals( expectedRoutes, routesViaStruct );
    }
    
    public void function testResourceWithMethodRestrictions() {

        var routes = variables.fw.getResourceRoutes( { resources = 'dogs', methods = 'default,update' } );        

        var expectedRoutes = [ 
            { '$GET/dogs/$' = '/dogs/default' },
            { '$PATCH/dogs/:id/$' = '/dogs/update/id/:id', '$PUT/dogs/:id/$' = '/dogs/update/id/:id' }
        ];

        assertEquals( expectedRoutes, routes );
    }

    public void function testResourceWithPathRoot() {

        var routes = variables.fw.getResourceRoutes( { resources = 'dogs', pathRoot = '/animals' } );        

        var expectedRoutes = [ 
            { '$GET/animals/dogs/$' = '/dogs/default' },
            { '$GET/animals/dogs/new/$' = '/dogs/new' },
            { '$POST/animals/dogs/$' = '/dogs/create' },
            { '$GET/animals/dogs/:id/$' = '/dogs/show/id/:id' },
            { '$PATCH/animals/dogs/:id/$' = '/dogs/update/id/:id', '$PUT/animals/dogs/:id/$' = '/dogs/update/id/:id' },
            { '$DELETE/animals/dogs/:id/$' = '/dogs/destroy/id/:id' }
        ];

        assertEquals( expectedRoutes, routes );
    }
    
    public void function testResourceWithSubsystem() {

        var routes = variables.fw.getResourceRoutes( { resources = 'dogs', subsystem = 'animals' } );        

        var expectedRoutes = [ 
            { '$GET/animals/dogs/$' = '/animals:dogs/default' },
            { '$GET/animals/dogs/new/$' = '/animals:dogs/new' },
            { '$POST/animals/dogs/$' = '/animals:dogs/create' },
            { '$GET/animals/dogs/:id/$' = '/animals:dogs/show/id/:id' },
            { '$PATCH/animals/dogs/:id/$' = '/animals:dogs/update/id/:id', '$PUT/animals/dogs/:id/$' = '/animals:dogs/update/id/:id' },
            { '$DELETE/animals/dogs/:id/$' = '/animals:dogs/destroy/id/:id' }
        ];

        assertEquals( expectedRoutes, routes );
    }
    
    public void function testResourceWithPathRootAndSubsystem() {

        var routes = variables.fw.getResourceRoutes( { resources = 'dogs', pathRoot = '/public', subsystem = 'animals' } );        

        var expectedRoutes = [ 
            { '$GET/public/animals/dogs/$' = '/animals:dogs/default' },
            { '$GET/public/animals/dogs/new/$' = '/animals:dogs/new' },
            { '$POST/public/animals/dogs/$' = '/animals:dogs/create' },
            { '$GET/public/animals/dogs/:id/$' = '/animals:dogs/show/id/:id' },
            { '$PATCH/public/animals/dogs/:id/$' = '/animals:dogs/update/id/:id', '$PUT/public/animals/dogs/:id/$' = '/animals:dogs/update/id/:id' },
            { '$DELETE/public/animals/dogs/:id/$' = '/animals:dogs/destroy/id/:id' }
        ];

        assertEquals( expectedRoutes, routes );
    }

    public void function testNestedResource() {

        var routes = variables.fw.getResourceRoutes( { resources = 'dogs', nested = 'toys' } );

        var expectedRoutes = [ 
            { '$GET/dogs/$' = '/dogs/default' },
            { '$GET/dogs/new/$' = '/dogs/new' },
            { '$POST/dogs/$' = '/dogs/create' },
            { '$GET/dogs/:id/$' = '/dogs/show/id/:id' },
            { '$PATCH/dogs/:id/$' = '/dogs/update/id/:id', '$PUT/dogs/:id/$' = '/dogs/update/id/:id' },
            { '$DELETE/dogs/:id/$' = '/dogs/destroy/id/:id' },
            { '$GET/dogs/:dogs_id/toys/$' = '/toys/default/dogs_id/:dogs_id' },
            { '$GET/dogs/:dogs_id/toys/new/$' = '/toys/new/dogs_id/:dogs_id' },
            { '$POST/dogs/:dogs_id/toys/$' = '/toys/create/dogs_id/:dogs_id' },
            { '$GET/dogs/:dogs_id/toys/:id/$' = '/toys/show/id/:id/dogs_id/:dogs_id' },
            { '$PATCH/dogs/:dogs_id/toys/:id/$' = '/toys/update/id/:id/dogs_id/:dogs_id', '$PUT/dogs/:dogs_id/toys/:id/$' = '/toys/update/id/:id/dogs_id/:dogs_id' },
            { '$DELETE/dogs/:dogs_id/toys/:id/$' = '/toys/destroy/id/:id/dogs_id/:dogs_id' }
        ];

        assertEquals( expectedRoutes, routes );
    }

    public void function testNestedResourceWithPathRoot() {

        var routes = variables.fw.getResourceRoutes( { resources = 'dogs', pathRoot = '/animals', nested = 'toys' } );

        var expectedRoutes = [ 
            { '$GET/animals/dogs/$' = '/dogs/default' },
            { '$GET/animals/dogs/new/$' = '/dogs/new' },
            { '$POST/animals/dogs/$' = '/dogs/create' },
            { '$GET/animals/dogs/:id/$' = '/dogs/show/id/:id' },
            { '$PATCH/animals/dogs/:id/$' = '/dogs/update/id/:id', '$PUT/animals/dogs/:id/$' = '/dogs/update/id/:id' },
            { '$DELETE/animals/dogs/:id/$' = '/dogs/destroy/id/:id' },
            { '$GET/animals/dogs/:dogs_id/toys/$' = '/toys/default/dogs_id/:dogs_id' },
            { '$GET/animals/dogs/:dogs_id/toys/new/$' = '/toys/new/dogs_id/:dogs_id' },
            { '$POST/animals/dogs/:dogs_id/toys/$' = '/toys/create/dogs_id/:dogs_id' },
            { '$GET/animals/dogs/:dogs_id/toys/:id/$' = '/toys/show/id/:id/dogs_id/:dogs_id' },
            { '$PATCH/animals/dogs/:dogs_id/toys/:id/$' = '/toys/update/id/:id/dogs_id/:dogs_id', '$PUT/animals/dogs/:dogs_id/toys/:id/$' = '/toys/update/id/:id/dogs_id/:dogs_id' },
            { '$DELETE/animals/dogs/:dogs_id/toys/:id/$' = '/toys/destroy/id/:id/dogs_id/:dogs_id' }
        ];

        assertEquals( expectedRoutes, routes );
    }
    
    public void function testNestedResourceWithSubsystem() {

        var routes = variables.fw.getResourceRoutes( { resources = 'dogs', subsystem = 'animals', nested = 'toys' } );

        var expectedRoutes = [ 
            { '$GET/animals/dogs/$' = '/animals:dogs/default' },
            { '$GET/animals/dogs/new/$' = '/animals:dogs/new' },
            { '$POST/animals/dogs/$' = '/animals:dogs/create' },
            { '$GET/animals/dogs/:id/$' = '/animals:dogs/show/id/:id' },
            { '$PATCH/animals/dogs/:id/$' = '/animals:dogs/update/id/:id', '$PUT/animals/dogs/:id/$' = '/animals:dogs/update/id/:id' },
            { '$DELETE/animals/dogs/:id/$' = '/animals:dogs/destroy/id/:id' },
            { '$GET/animals/dogs/:dogs_id/toys/$' = '/animals:toys/default/dogs_id/:dogs_id' },
            { '$GET/animals/dogs/:dogs_id/toys/new/$' = '/animals:toys/new/dogs_id/:dogs_id' },
            { '$POST/animals/dogs/:dogs_id/toys/$' = '/animals:toys/create/dogs_id/:dogs_id' },
            { '$GET/animals/dogs/:dogs_id/toys/:id/$' = '/animals:toys/show/id/:id/dogs_id/:dogs_id' },
            { '$PATCH/animals/dogs/:dogs_id/toys/:id/$' = '/animals:toys/update/id/:id/dogs_id/:dogs_id', '$PUT/animals/dogs/:dogs_id/toys/:id/$' = '/animals:toys/update/id/:id/dogs_id/:dogs_id' },
            { '$DELETE/animals/dogs/:dogs_id/toys/:id/$' = '/animals:toys/destroy/id/:id/dogs_id/:dogs_id' }
        ];

        assertEquals( expectedRoutes, routes );
    }

    public void function testNestedResourceMethodRestrictions() {
        var routes = variables.fw.getResourceRoutes( { resources = 'dogs', methods = 'default', nested = { resources = 'toys', methods = 'new' } } );

        var expectedRoutes = [ 
            { '$GET/dogs/$' = '/dogs/default' },
            { '$GET/dogs/:dogs_id/toys/new/$' = '/toys/new/dogs_id/:dogs_id' }
        ];

        assertEquals( expectedRoutes, routes );
    }

    public void function testNestedResourcePathRootShouldBeIgnored() {
        // pathRoot should be ignored on nested resource structs to prevent the parent resource path from getting overwritten
        var routes = variables.fw.getResourceRoutes( { resources = 'dogs', pathRoot = '/public', methods = 'default', nested = { resources = 'toys', pathRoot = '/private', methods = 'new' } } );

        var expectedRoutes = [ 
            { '$GET/public/dogs/$' = '/dogs/default' },
            { '$GET/public/dogs/:dogs_id/toys/new/$' = '/toys/new/dogs_id/:dogs_id' }
        ];

        assertEquals( expectedRoutes, routes );
    }

    public void function testNestedResourceSubsystemShouldBeIgnored() {
        // should nested subsystem be ignored? seems likely...but not sure about this
        var routes = variables.fw.getResourceRoutes( { resources = 'dogs', subsystem = 'public', methods = 'default', nested = { resources = 'toys', subsystem = 'private', methods = 'new' } } );

        var expectedRoutes = [ 
            { '$GET/public/dogs/$' = '/public:dogs/default' },
            { '$GET/public/dogs/:dogs_id/toys/new/$' = '/public:toys/new/dogs_id/:dogs_id' }
        ];

        assertEquals( expectedRoutes, routes );
    }

    // PRIVATE

    private boolean function isFrameworkInitialized() {
        return false;
    }
}
