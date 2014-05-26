component extends="tests.InjectableTest" {

    public void function setUp() {
        variables.fw = new org.corfield.framework();
        // doesn't work on Railo:
        // makePublic(variables.fw, "processRouteMatch");
        // this works on both Railo and ACF:
        variables.fw.processRouteMatch = getVariablesScope(variables.fw).processRouteMatch;
    }

    public void function testRouteMatchBasics()
    {
        var match = variables.fw.processRouteMatch("/test", "routed", "/test");        
        assertTrue(match.matched);
        assertEquals("/test/(.*)", match.pattern);
        assertEquals("routed/\1", match.target);
                
        match = variables.fw.processRouteMatch("/test2/:id", "default.main?id=:id", "/test2/5");      
        assertTrue(match.matched);
        assertEquals("/test2/([^/]*)/(.*)", match.pattern);
        assertEquals("default.main?id=\1/\2", match.target);
        
        match = variables.fw.processRouteMatch("/test2/:id", "default.main?id=:id", "/test2");        
        assertFalse(match.matched);
        
        match = variables.fw.processRouteMatch("/test/:foo/bar/:baz", "default.main?foo=:foo&baz=:baz", "/test/quux/bar/fnarf");
        assertTrue(match.matched);
        assertEquals("/test/([^/]*)/bar/([^/]*)/(.*)", match.pattern);
        assertEquals("default.main?foo=\1&baz=\2/\3", match.target);
    }
    
    public void function testRouteMatchRegex()
    {
        match = variables.fw.processRouteMatch("/test2/:id", "default.main?id=:id", "/test2/5/people");      
        assertTrue(match.matched);
        
        match = variables.fw.processRouteMatch("/(blog|forum|forums)/:action/", "/forum::action/", "/blog/post");
        assertTrue(match.matched);
        assertEquals("/forum:post/", rereplace( match.path, match.pattern, match.target ));      
        
        match = variables.fw.processRouteMatch("/test2/:id/", "default.main?id=:id", "/test2/5/people");
        assertTrue(match.matched, "/test2/:id should match /test2/5/people");
        
        match = variables.fw.processRouteMatch("/test2/:id/$", "default.main?id=:id", "/test2/5/people");
        assertFalse(match.matched, "/test2/:id/$ shouldn't match /test2/5/people");
        
        match = variables.fw.processRouteMatch("/test2/(\d+)/$", "default.main/id/\1/", "/test2/5");
        assertTrue(match.matched);
        assertEquals("default.main/id/5/", rereplace(match.path, match.pattern, match.target));
        
        match = variables.fw.processRouteMatch("/test2/(\d+)/$", "default.main/id/\1/", "/test2/zz/");
        assertFalse(match.matched);
        
        var route = "/test/(\d+)/something(\.)?(\w+)?/$";
        var target = "default.main/id/\1/type/\3/";
        match = variables.fw.processRouteMatch(route, target, "/test/5/something/");
        assertTrue(match.matched, "/test/5/something/ should match");
        assertEquals("default.main/id/5/type//", rereplace(match.path, match.pattern, match.target));
        
        match = variables.fw.processRouteMatch(route, target, "/test/5/something.html/");
        assertTrue(match.matched);
        assertEquals("default.main/id/5/type/html/", rereplace(match.path, match.pattern, match.target));
    }
    
    public void function testRouteMatchMethod()
    {
        match = variables.fw.processRouteMatch("$GET/test/:id", "default.main?id=:id", "/test/5");
        assertTrue(match.matched);
        
        match = variables.fw.processRouteMatch("$POST/test/:id", "default.main?id=:id", "/test/5");
        assertFalse(match.matched);           
    }
    
    public void function testRouteMatchRedirect()
    {
        match = variables.fw.processRouteMatch("/test/:id", "default.main?id=:id", "/test/5");
        assertTrue(match.matched);
        assertFalse(match.redirect);
        
        match = variables.fw.processRouteMatch("/test/:id", "302:default.main?id=:id", "/test/5");
        assertTrue(match.matched);
        assertTrue(match.redirect);
        assertEquals(302, match.statusCode);
    }

    public void function testCustomURL() {
        variables.fw.onApplicationStart();
        // since we are not running FW/1 "properly", get the stem of the
        // test suite file as the prefix, so lets strip anything up to the .cfm
        var uri = variables.fw.buildCustomURL( "/product/123" );
        uri = REReplace( uri, "^.*\.cf[cm]", "" );
        assertEquals( "/product/123", uri );
    }
}
