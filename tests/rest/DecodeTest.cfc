component extends="mxunit.framework.TestCase" {

    function testURLEncodedRequestDecodesMultiField() {
        var actual = doURLEncodedHTTPRequest( "GET" );
        assertEquals( "GET", actual.method );
        assertEquals( "a,b,c", actual.single );
        assertEquals( "1,2,3,40,50", actual.multi );
    }

    function testPostFormEncodedRequestDecodesMultiField() {
        var actual = doFormEncodedHTTPRequest( "POST" );
        assertEquals( "POST", actual.method );
        assertEquals( "a,b,c", actual.single );
        assertEquals( "1,2,3,40,50", actual.multi );
    }

    function testPatchFormEncodedRequestDecodesMultiField() skip="engineNotSupported" {
        var actual = doFormEncodedHTTPRequest( "PATCH" );
        assertEquals( "PATCH", actual.method );
        assertEquals( "a,b,c", actual.single );
        assertEquals( "1,2,3,40,50", actual.multi );
    }

    function testPutFormEncodedRequestDecodesMultiField() {
        var actual = doFormEncodedHTTPRequest( "PUT" );
        assertEquals( "PUT", actual.method );
        assertEquals( "a,b,c", actual.single );
        assertEquals( "1,2,3,40,50", actual.multi );
    }
    
    function testPostJSONEncodedRequestDecodesMultiField() {
        var actual = doJSONEncodedHTTPRequest( "POST" );
        assertEquals( "POST", actual.method );
        assertEquals( "a,b,c", actual.single );
        assertEquals( "1,2,3,40,50", actual.multi );
    }

    function testPatchJSONRequestDecodesMultiField() skip="engineNotSupported" {
        var actual = doJSONEncodedHTTPRequest( "PATCH" );
        assertEquals( "PATCH", actual.method );
        assertEquals( "a,b,c", actual.single );
        assertEquals( "1,2,3,40,50", actual.multi );
    }

    function testPutJSONRequestDecodesMultiField() {
        var actual = doJSONEncodedHTTPRequest( "PUT" );
        assertEquals( "PUT", actual.method );
        assertEquals( "a,b,c", actual.single );
        assertEquals( "1,2,3,40,50", actual.multi );
    }



    private function doFormEncodedHTTPRequest( verb ) {
        return doHTTPRequest( verb, "application/x-www-form-urlencoded", "multi=1%2C2%2C3&multi=40&multi=50&single=a%2Cb%2Cc" );
    }
    
    private function doURLEncodedHTTPRequest( verb ) {
        return doHTTPRequest( verb, "application/x-www-form-urlencoded", "&multi=1%2C2%2C3&multi=40&multi=50&single=a%2Cb%2Cc" );
    }

    private function doJSONEncodedHTTPRequest( verb ) {
        return doHTTPRequest( verb, "application/json", '{"multi": "1,2,3,40,50","single": "a,b,c"}' );
    }

    private function doHTTPRequest( verb, contentType, body ) {

        if (verb eq "GET") {
            http method="#verb#" charset="utf-8" url="http://#CGI.SERVER_NAME#:#CGI.SERVER_PORT#/examples/rest/" result="httpResult" {                
                httpparam type="url" name="action" value="main.#verb#";
                httpparam type="url" name="multi" value="1,2,3";
                httpparam type="url" name="multi" value="40";
                httpparam type="url" name="multi" value="50";
                httpparam type="url" name="single" value="a,b,c";
            }
        } else {
            http method="#verb#" charset="utf-8" url="http://#CGI.SERVER_NAME#:#CGI.SERVER_PORT#/examples/rest/?action=main.#verb#" result="httpResult" {
                httpparam type="header" name="content-type" value="#contentType#";
                httpparam type="body" value="#body#";
            }
        }

        var response = httpResult.filecontent;
        if ( isJson( response ) ) {
            return deserializeJSON( response );
        }
        fail( "expected a JSON response for #verb# #contentType#" );
    }

    function engineNotSupported() {
        return server.coldfusion.productname != "Lucee" && ListFirst( server.coldfusion.productversion ) == 10;
    }

}
