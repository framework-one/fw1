component extends=framework.one {

    function setupApplication() {
        var mustacheFactory = "com.github.mustachejava.DefaultMustacheFactory";
        var mustacheJAR = expandPath( "compiler-0.9.1.jar" );
        var viewRoot = expandPath( "/" );
        application.mustache = createObject( "java", mustacheFactory, mustacheJAR ).init(
            createObject( "java", "java.io.File" ).init( viewRoot )
        );
    }

    public string function customizeViewOrLayoutPath( struct pathInfo, string type, string fullPath ) {
        if ( type == "view" ) return '#pathInfo.base##type#s/#pathInfo.path#.html';
        else return fullPath;
    }

    private string function internalView( string viewPath, struct args = { } ) {
        var writer = createObject( "java", "java.io.StringWriter" ).init();
        var template = application.mustache.compile( viewPath );
        template.execute( writer, request.context );
        writer.flush();
        return writer.toString();
    }

}
