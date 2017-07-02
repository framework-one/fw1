component extends=framework.one {

    variables.mustacheJAR = expandPath( "compiler-0.9.1.jar" );
    this.javaSettings.loadPaths = [ variables.mustacheJAR ];

    function setupApplication() {
        var mustacheFactory = "com.github.mustachejava.DefaultMustacheFactory";
        var viewRoot = expandPath( "/" );
        application.mustache = createObject(
            "java", mustacheFactory
        ).init(
            createObject( "java", "java.io.File" ).init( viewRoot )
        );
    }

    function setupView( rc ) {
        variables.mustacheProxies = makeMethodProxies( [ "buildURL", "view" ] );
    }

    // we must override this to change the file extension that FW/1 looks for:
    public string function customizeViewOrLayoutPath( struct pathInfo, string type, string fullPath ) {
        return '#pathInfo.base##type#s/#pathInfo.path#.html';
    }

    public any function customTemplateEngine( string type, string path, struct scope ) {
        // so mustache can see these functions:
        scope.fw1 = variables.mustacheProxies;
        // compile & execute the template:
        var template = application.mustache.compile( path );
        var writer = createObject( "java", "java.io.StringWriter" ).init();
        template.execute( writer, [ scope ] );
        writer.flush();
        return writer.toString();
    }

}
