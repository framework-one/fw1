component extends="tests.InjectableTest" {

    public void function setUp() {
        variables.fw = new framework.one();
        request._fw1.requestDefaultsInitialized = false;
        variables.fwVars = getVariablesScope( variables.fw );
        variables.fwVars.framework.routesCaseSensitive = true;
        // make method public:
        variables.fw.processRouteMatch = variables.fwVars.processRouteMatch;
        variables.fw.onApplicationStart();
    }

    public void function testRouteMatchBasics()
    {
        var match = variables.fw.processRouteMatch("/test", "routed", "/test", "GET");
        assertTrue(match.matched);
        assertEquals("/test/(.*)", match.pattern);
        assertEquals("routed/\1", match.target);

        match = variables.fw.processRouteMatch("/", "routed", "/test", "GET");
        assertTrue(match.matched);
        assertEquals("/(.*)", match.pattern);
        assertEquals("routed/\1", match.target);

        match = variables.fw.processRouteMatch("/test2/:id", "default.main?id=:id", "/test2/5", "GET");
        assertTrue(match.matched);
        assertEquals("/test2/([^/]*)/(.*)", match.pattern);
        assertEquals("default.main?id=\1/\2", match.target);

        match = variables.fw.processRouteMatch("/test2/:id", "default.main?id=:id", "/test2", "GET");
        assertFalse(match.matched);

        match = variables.fw.processRouteMatch("/test/:foo/bar/:baz", "default.main?foo=:foo&baz=:baz", "/test/quux/bar/fnarf", "GET");
        assertTrue(match.matched);
        assertEquals("/test/([^/]*)/bar/([^/]*)/(.*)", match.pattern);
        assertEquals("default.main?foo=\1&baz=\2/\3", match.target);
    }

    public void function testRouteMatchRegex()
    {
        match = variables.fw.processRouteMatch("/test2/:id", "default.main?id=:id", "/test2/5/people", "GET");
        assertTrue(match.matched);

        match = variables.fw.processRouteMatch("/(blog|forum|forums)/:action/", "/forum::action/", "/blog/post", "GET");
        assertTrue(match.matched);
        assertEquals("/forum:post/", rereplace( match.path, match.pattern, match.target ));

        match = variables.fw.processRouteMatch("/test2/:id/", "default.main?id=:id", "/test2/5/people", "GET");
        assertTrue(match.matched, "/test2/:id should match /test2/5/people");

        match = variables.fw.processRouteMatch("/test2/:id/$", "default.main?id=:id", "/test2/5/people", "GET");
        assertFalse(match.matched, "/test2/:id/$ shouldn't match /test2/5/people");

        match = variables.fw.processRouteMatch("/test2/(\d+)/$", "default.main/id/\1/", "/test2/5", "GET");
        assertTrue(match.matched);
        assertEquals("default.main/id/5/", rereplace(match.path, match.pattern, match.target));

        match = variables.fw.processRouteMatch("/test2/(\d+)/$", "default.main/id/\1/", "/test2/zz/", "GET");
        assertFalse(match.matched);

        var route = "/test/(\d+)/something(\.)?(\w+)?/$";
        var target = "default.main/id/\1/type/\3/";
        match = variables.fw.processRouteMatch(route, target, "/test/5/something/", "GET");
        assertTrue(match.matched, "/test/5/something/ should match");
        assertEquals("default.main/id/5/type//", rereplace(match.path, match.pattern, match.target));

        match = variables.fw.processRouteMatch(route, target, "/test/5/something.html/", "GET");
        assertTrue(match.matched);
        assertEquals("default.main/id/5/type/html/", rereplace(match.path, match.pattern, match.target));

        match = variables.fw.processRouteMatch("/product/{id:[0-9]+}-:name.html", "product.detail?id=:id&name=:name", "/product/1-computer.html", "GET");
        assertTrue(match.matched);
        assertEquals("product.detail?id=1&name=computer/", rereplace(match.path, match.pattern, match.target));
    }

    public void function testRouteMatchMethod()
    {
        match = variables.fw.processRouteMatch("$GET/test/:id", "default.main?id=:id", "/test/5", "GET");
        assertTrue(match.matched);

        match = variables.fw.processRouteMatch("$POST/test/:id", "default.main?id=:id", "/test/5", "GET");
        assertFalse(match.matched);

        match = variables.fw.processRouteMatch("$GET/test/:id", "default.main?id=:id", "/test/5", "POST");
        assertFalse(match.matched);

        match = variables.fw.processRouteMatch("$POST/test/:id", "default.main?id=:id", "/test/5", "POST");
        assertTrue(match.matched);

        match = variables.fw.processRouteMatch("$POST^/foo/test/:id", "default.main?id=:id", "/foo/test/5", "POST");
        assertTrue(match.matched);

        match = variables.fw.processRouteMatch("$POST^/test/:id", "default.main?id=:id", "/foo/test/5", "POST");
        assertFalse(match.matched);

        match = variables.fw.processRouteMatch("$*^/test/:id", "default.main?id=:id", "/test/5", "GET");
        assertTrue(match.matched);

        match = variables.fw.processRouteMatch("$*^/test/:id", "default.main?id=:id", "/test/5", "POST");
        assertTrue(match.matched);

        match = variables.fw.processRouteMatch("$*^/test/:id", "default.main?id=:id", "/foo/test/5", "GET");
        assertFalse(match.matched);

        match = variables.fw.processRouteMatch("$*^/test/:id", "default.main?id=:id", "/foo/test/5", "POST");
        assertFalse(match.matched);

        match = variables.fw.processRouteMatch("$*", "default.error", "/foo/test/5", "GET");
        assertTrue(match.matched);

        match = variables.fw.processRouteMatch("$*", "default.error", "/foo/test/5", "POST");
        assertTrue(match.matched);

        // issue 476 : trailing EOL regex marker should prevent match (only with ^):
        match = variables.fw.processRouteMatch("$GET/$", "default.error", "/foo/test/5", "GET");
        assertTrue(match.matched);
        match = variables.fw.processRouteMatch("$GET^/$", "default.error", "/foo/test/5", "GET");
        assertFalse(match.matched);
    }

    public void function testRouteMatchRedirect()
    {
        match = variables.fw.processRouteMatch("/test/:id", "default.main?id=:id", "/test/5", "GET");
        assertTrue(match.matched);
        assertFalse(match.redirect);

        match = variables.fw.processRouteMatch("/test/:id", "302:default.main?id=:id", "/test/5", "GET");
        assertTrue(match.matched);
        assertTrue(match.redirect);
        assertEquals(302, match.statusCode);
    }

    public void function testCustomURL() {
        // since we are not running FW/1 "properly", get the stem of the
        // test suite file as the prefix, so lets strip anything up to the .cfm
        var uri = variables.fw.buildCustomURL( "/product/123" );
        uri = REReplace( uri, "^.*\.cf[cm]", "" );
        assertEquals( "/product/123", uri );
    }

    public void function testCustomURLWithVariables() {
        // setup our RC:
        request.context = { id = 123, type = "string", ignore = { notSimple = 123 } };
        // since we are not running FW/1 "properly", get the stem of the
        // test suite file as the prefix, so lets strip anything up to the .cfm
        var uri = variables.fw.buildCustomURL( "/product/:id" );
        uri = REReplace( uri, "^.*\.cf[cm]", "" );
        assertEquals( "/product/123", uri );
        var uri = variables.fw.buildCustomURL( "/product/hide:id" );
        uri = REReplace( uri, "^.*\.cf[cm]", "" );
        assertEquals( "/product/hide:id", uri );
        var uri = variables.fw.buildCustomURL( "/test?:id=:type" );
        uri = REReplace( uri, "^.*\.cf[cm]", "" );
        assertEquals( "/test?123=string", uri );
        var uri = variables.fw.buildCustomURL( "/product/:ignore" );
        uri = REReplace( uri, "^.*\.cf[cm]", "" );
        assertEquals( "/product/:ignore", uri );
    }

}
