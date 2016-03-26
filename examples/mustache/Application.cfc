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
        // normal view setup:
        var rc = request.context;
        var $ = { };
        // integration point with Mura:
        if ( structKeyExists( rc, '$' ) ) {
            $ = rc.$;
        }
        structAppend( local, args );
        // *** start of specific rendering logic ***
        // add proxies for useful FW/1 methods:
        var fw1 = { };
        var methods = [ "buildURL", "view" ];
        for ( var method in methods ) {
            fw1[ method ] = createDynamicProxy(
                new framework.methodProxy( this, method ),
                [ "java.util.function.Function" ]
            );
        }
        // compile & execute the template:
        var template = application.mustache.compile( viewPath );
        var writer = createObject( "java", "java.io.StringWriter" ).init();
        template.execute( writer, local );
        writer.flush();
        return writer.toString();
    }

}
