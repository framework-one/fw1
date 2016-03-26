component extends=framework.one {

    function setupApplication() {
        var mustacheFactory = "com.github.mustachejava.DefaultMustacheFactory";
        var mustacheJAR = expandPath( "." ) & "/compiler-0.9.1.jar";
        var viewRoot = expandPath( "views" );
        application.mustache = createObject( "java", mustacheFactory, mustacheJAR ).init(
            createObject( "java", "java.io.File" ).init( viewRoot )
        );
    }

}
