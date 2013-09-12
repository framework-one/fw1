component extends="fw1.tests.InjectableTest" {

    public void function setUp() {
        variables.fw = new org.corfield.framework();
        variables.fw.generateRoutes = getVariablesScope( variables.fw ).generateRoutes;
        variables.fw.processRoutes = getVariablesScope( variables.fw ).processRoutes;
        getVariablesScope( variables.fw ).framework = {
            routeDefinitions = {
                '$RESOURCES' = { 
                    '$GET/{1}/$' = '/{1}/index', '$GET/{1}/new/$' = '/{1}/new', '$POST/{1}/$' = '/{1}/create', 
                    '$GET/{1}/:id/$' = '/{1}/show/id/:id', '$PUT/{1}/:id/$' = '/{1}/update/id/:id', '$DELETE/{1}/:id/$' = '/{1}/destroy/id/:id'
                },
                '$SUBRESOURCES' = {
                    '$GET/{2}/:{3}/{1}/$' = '/{1}/index/{3}/:{3}', '$GET/{2}/:{3}/{1}/new/$' = '/{1}/new/{3}/:{3}', '$POST/{2}/:{3}/{1}/$' = '/{1}/create/{3}/:{3}',
                    '$GET/{2}/:{3}/{1}/:id/$' = '/{1}/show/id/:id/{3}/:{3}', '$PUT/{2}/:{3}/{1}/:id/$' = '/{1}/update/id/:id/{3}/:{3}', '$DELETE/{2}/:{3}/{1}/:id/$' = '/{1}/destroy/id/:id/{3}/:{3}'
                },
                '$REST' = [ 
                    { '$GET/{1}/new' = '/{1}/new' }, 
                    { '$GET/{1}/:{2}' = '/{1}/show/{2}/:{2}' }, 
                    { '$GET/{1}' = '/{1}/index' }, 
                    { '$POST/{1}' = '/{1}/create' },
                    { '$PUT/{1}/:{2}' = '/{1}/update/{2}/:{2}' },
                    { '$DELETE/{1}/:{2}' = '/{1}/destroy/{2}/:{2}' }
                ]
            },
            routes = [
                { '$RESOURCES/posts' = 'posts', '$SUBRESOURCES/posts' = 'comments,posts,post_id' },
                { '$REST' = 'comments,comment_id' }             
            ]
        };
    }

    public void function testGenerateRoutes()
    {
        var generatedRoutes = variables.fw.generateRoutes( '$RESOURCES', 'users' );
        var expectedRoutes = { 
            '$GET/users/$' = '/users/index', '$GET/users/new/$' = '/users/new', '$POST/users/$' = '/users/create', 
            '$GET/users/:id/$' = '/users/show/id/:id', '$PUT/users/:id/$' = '/users/update/id/:id', '$DELETE/users/:id/$' = '/users/destroy/id/:id'
        }
        debug( generatedRoutes );     
        assertEquals( 1, arrayLen( generatedRoutes ) );
        assertEquals( expectedRoutes, generatedRoutes[ 1 ] );

        var generatedRoutes = variables.fw.generateRoutes( '$SUBRESOURCES', 'comments,posts,post_id' );
        var expectedRoutes = {
            '$GET/posts/:post_id/comments/$' = '/comments/index/post_id/:post_id', '$GET/posts/:post_id/comments/new/$' = '/comments/new/post_id/:post_id', '$POST/posts/:post_id/comments/$' = '/comments/create/post_id/:post_id',
            '$GET/posts/:post_id/comments/:id/$' = '/comments/show/id/:id/post_id/:post_id', '$PUT/posts/:post_id/comments/:id/$' = '/comments/update/id/:id/post_id/:post_id', '$DELETE/posts/:post_id/comments/:id/$' = '/comments/destroy/id/:id/post_id/:post_id'
        }
        debug( generatedRoutes );     
        assertEquals( 1, arrayLen( generatedRoutes ) );
        assertEquals( expectedRoutes, generatedRoutes[ 1 ] );

        var generatedRoutes = variables.fw.generateRoutes( '$REST', 'users,user_id' );
        var expectedRoutes = [
            { '$GET/users/new' = '/users/new' },
            { '$GET/users/:user_id' = '/users/show/user_id/:user_id' },
            { '$GET/users' = '/users/index' },
            { '$POST/users' = '/users/create' },
            { '$PUT/users/:user_id' = '/users/update/user_id/:user_id' },
            { '$DELETE/users/:user_id' = '/users/destroy/user_id/:user_id' }
        ]
        debug( generatedRoutes );     
        assertEquals( 6, arrayLen( generatedRoutes ) );
        assertEquals( expectedRoutes, generatedRoutes );

    }

    public void function testRoutesGeneratedFromDefinitions()
    {
        request._fw1.cgiRequestMethod = 'GET';

        var match = variables.fw.processRoutes( "/posts/1" );   
        debug( match );     
        assertTrue( match.matched );
        assertEquals( "/posts/([^/]*)/$", match.pattern );
        assertEquals( "/posts/show/id/\1/\2", match.target );
        assertEquals( rereplace( match.path, match.pattern, match.target ), '/posts/show/id/1/' );

        var match = variables.fw.processRoutes( "/posts/1/comments" );   
        debug( match );     
        assertTrue( match.matched );
        assertEquals( "/posts/([^/]*)/comments/$", match.pattern );
        assertEquals( "/comments/index/post_id/\1/\2", match.target );
        assertEquals( rereplace( match.path, match.pattern, match.target ), '/comments/index/post_id/1/' );

        var match = variables.fw.processRoutes( "/comments/2" );   
        debug( match );     
        assertTrue( match.matched );
        assertEquals( "/comments/([^/]*)/(.*)", match.pattern );
        assertEquals( "/comments/show/comment_id/\1/\2", match.target );
        assertEquals( rereplace( match.path, match.pattern, match.target ), '/comments/show/comment_id/2/' );

        request._fw1.cgiRequestMethod = 'DELETE';

        var match = variables.fw.processRoutes( "/posts/1" );   
        debug( match );     
        assertTrue( match.matched );
        assertEquals( "/posts/([^/]*)/$", match.pattern );
        assertEquals( "/posts/destroy/id/\1/\2", match.target );
        assertEquals( rereplace( match.path, match.pattern, match.target ), '/posts/destroy/id/1/' );

        var match = variables.fw.processRoutes( "/posts/1/comments/3" );   
        debug( match );     
        assertTrue( match.matched );
        assertEquals( "/posts/([^/]*)/comments/([^/]*)/$", match.pattern );
        assertEquals( "/comments/destroy/id/\2/post_id/\1/\3", match.target );
        assertEquals( rereplace( match.path, match.pattern, match.target ), '/comments/destroy/id/3/post_id/1/' );

        var match = variables.fw.processRoutes( "/comments/2" );   
        debug( match );     
        assertTrue( match.matched );
        assertEquals( "/comments/([^/]*)/(.*)", match.pattern );
        assertEquals( "/comments/destroy/comment_id/\1/\2", match.target );
        assertEquals( rereplace( match.path, match.pattern, match.target ), '/comments/destroy/comment_id/2/' );
               
    }    
 
}