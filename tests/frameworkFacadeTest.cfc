component extends="mxunit.framework.TestCase" {

    function setup() {
        structDelete( request, "_fw1" ); // clean up the request
    }

    function testFacadeOnNonFW1Request() {
        try {
            var facade = new framework.facade();
            fail( "facade creation did not fail" );
        } catch ( FW1.FacadeException e ) {
            assertEquals( "Unable to locate FW/1 for this request", e.message );
        } catch ( any e ) {
            fail( "caught unexpected exception: " & e.message );
        }
    }

    function testFacadeWithFW1() {
        var fw = new framework.one();
        fw.onRequestStart( "" );
        var facade = new framework.facade();
        assertTrue( structKeyExists( facade, "getBeanFactory" ), "Constructed facade does not look like FW/1" );
    }

}
