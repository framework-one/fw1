component accessors=true {

    property framework;

    function default( rc ) {
        var viewPath = "main/default.html";
        var writer = createObject( "java", "java.io.StringWriter" ).init();
        var template = application.mustache.compile( viewPath );
        template.execute( writer, rc );
        writer.flush();

        framework.renderData().type( "html" ).data( writer.toString() );
    }

}
