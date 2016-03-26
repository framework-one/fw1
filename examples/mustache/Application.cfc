component extends=framework.one {

    function setupApplication() {
        var mustacheFactory = "com.github.mustachejava.DefaultMustacheFactory";
        var mustacheJAR = expandPath( "." ) & "/compiler-0.9.1.jar";
        var viewRoot = expandPath( "views" );
        application.mustache = createObject( "java", mustacheFactory, mustacheJAR ).init(
            createObject( "java", "java.io.File" ).init( viewRoot )
        );
    }

    function render_mustache( struct renderData ) {
        // NOTE: evaluated outside FW/1 context as a pure function
        var viewPath = "main/default.html"; // TODO: calculate this!
        var writer = createObject( "java", "java.io.StringWriter" ).init();
        var template = application.mustache.compile( viewPath );
        template.execute( writer, request.context );
        writer.flush();
        // since we're rendering HTML
        structDelete( request._fw1, "renderData" );
        return {
            contentType = "text/html; charset=utf-8",
            output = writer.toString()
        };
    }

}
