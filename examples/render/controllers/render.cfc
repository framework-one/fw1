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

    public void function jsonString( struct rc ) {
        variables.fw.renderData( 'rawjson', '[ "An", "array", { "containing" = "data" } ]' );
    }

    public void function html( struct rc ) {
        variables.fw.renderData( 'html', '<h1>Some HTML</h1><p>Passed to renderData().</p>' );
    }

}
