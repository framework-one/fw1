component extends="mxunit.framework.TestCase" {

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

    private function doJSONEncodedHTTPRequest( verb ) {
        return doHTTPRequest( verb, "application/json", '{"multi": "1,2,3,40,50","single": "a,b,c"}' );
    }

    private function doHTTPRequest( verb, contentType, body ) {
        var result = {};
        cfhttp( method=verb, charset="utf-8", url="http://#CGI.SERVER_NAME#:#CGI.SERVER_PORT#/tests/rest/fixture/?action=main.#verb#", result="local.result" ) {
            cfhttpparam( type="header", name="content-type", value=contentType );
            cfhttpparam( type="body", value=body );
        }
        var response = result.filecontent;
        if ( isJson( response ) ) {
            return deserializeJSON( response );
        }
        fail( "expected a JSON response for #verb# #contentType#; HTTP #result.statusCode#; response: #left( response, 2000 )#" );
    }

    function engineNotSupported() {
        return server.coldfusion.productname != "Lucee" && ListFirst( server.coldfusion.productversion ) == 10;
    }

}
