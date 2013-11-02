component {

    public any function init( any fw ) {
        variables.fw = fw;
        return this;
    }

    public void function someText( struct rc ) {
        variables.fw.renderData( 'text', 'This should just be plain text' );
    }

    public void function xmlString( struct rc ) {
        variables.fw.renderData( 'xml', '<some><xml with="an" attribute="value">And a body!</xml></some>' );
    }

    public void function xmlObject( struct rc ) {
        var xmlData = xmlParse( '<some><xml with="an" attribute="value">And a body!</xml></some>' );
        variables.fw.renderData( 'xml', xmlData );
    }

    public void function jsonObject( struct rc ) {
        variables.fw.renderData( 'json', [ "An", "array", { "containing" = "data" } ] );
    }

}
