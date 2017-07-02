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

    // we must override this to change the file extension that FW/1 looks for:
    public string function customizeViewOrLayoutPath( struct pathInfo, string type, string fullPath ) {
        return '#pathInfo.base##type#s/#pathInfo.path#.html';
    }

    public any function customizeRendering( string type, string path, struct scope ) {
        scope.fw1 = { };
        var methods = [ "buildURL", "view" ];
        for ( var method in methods ) {
            scope.fw1[ method ] = createDynamicProxy(
                new framework.methodProxy( this, method ),
                [ "java.util.function.Function" ]
            );
        }
        // compile & execute the template:
        var template = application.mustache.compile( path );
        var writer = createObject( "java", "java.io.StringWriter" ).init();
        template.execute( writer, [ scope ] );
        writer.flush();
        return writer.toString();
    }

}
