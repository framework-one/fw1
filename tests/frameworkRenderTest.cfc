component extends="mxunit.framework.TestCase" {

    public void function setUp() {
        structDelete(request,"_fw1"); // force a reset of tracing vars
        variables.fw = new framework.one();
        variables.fw.enableTracing = _enableTracing;
        variables.fw.enableTracing();
        request.fw = new framework.one();
        request.fw.enableTracing = _enableTracing;
        request.fw.enableTracing();
        variables.fwExtended = new traceRender.one();
        variables.fwExtended.enableTracing = _enableTracing;
        variables.fwExtended.enableTracing();
    }

    private void function _enableTracing() {
        variables.framework.trace = true;
    }

    public void function testTraceOutputVar() {
        variables.fw.onApplicationStart();
        var output = "";
        savecontent variable="output" {
            variables.fw.onRequestEnd();
        }
        assertTrue( output contains "framework lifecycle trace" );
    }

    public void function testTraceOutputVarDisabled() {
        variables.fw.onApplicationStart();
        request.fw.disableFrameworkTrace();
        var output = "";
        savecontent variable="output" {
            variables.fw.onRequestEnd();
        }
        assertFalse( output contains "framework lifecycle trace" );
    }

    public void function testTraceEmptyOutputReq() {
        request.fw.onApplicationStart();
        var output = "";
        savecontent variable="output" {
            request.fw.onRequestEnd();
        }
        assertTrue( output contains "framework lifecycle trace" );
    }

    public void function testNoTraceRenderVar() {
        variables.fw.onApplicationStart();
        variables.fw.renderData( "text", "test" );
        var output = "";
        savecontent variable="output" {
            variables.fw.onRequestEnd();
        }
        assertFalse( output contains "framework lifecycle trace" );
    }

    public void function testTraceOutputReq() {
        request.fw.onApplicationStart();
        variables.fw.renderData( "text", "myteststring" );
        var output = "";
        savecontent variable="output" {
            request.fw.onRequest("/index.cfm");
            request.fw.onRequestEnd();
        }
        assertTrue( output contains "myteststring" );
        assertFalse( output contains "framework lifecycle trace" );
    }

    public void function testTraceOutputHTMLReq() {
        request.fw.onApplicationStart();
        variables.fw.renderData( "html", "<p>myteststring</p>" );
        var output = "";
        savecontent variable="output" {
            request.fw.onRequest("/index.cfm");
            request.fw.onRequestEnd();
        }
        assertTrue( output contains "myteststring" );
        assertTrue( output contains "framework lifecycle trace" );
    }

    public void function testNoTraceRenderVarBuilder() {
        variables.fw.onApplicationStart();
        variables.fw.renderData( "text" ).data( "test" );
        var output = "";
        savecontent variable="output" {
            variables.fw.onRequestEnd();
        }
        assertFalse( output contains "framework lifecycle trace" );
    }

    public void function testTraceOutputReqBuilder() {
        request.fw.onApplicationStart();
        variables.fw.renderData().type( "text" ).data( "myteststring" );
        var output = "";
        savecontent variable="output" {
            request.fw.onRequest("/index.cfm");
            request.fw.onRequestEnd();
        }
        assertTrue( output contains "myteststring" );
        assertFalse( output contains "framework lifecycle trace" );
    }

    public void function testTraceOutputHTMLReqBuilder() {
        request.fw.onApplicationStart();
        variables.fw.renderData( data = "<p>myteststring</p>" ).type( "html" );
        var output = "";
        savecontent variable="output" {
            request.fw.onRequest("/index.cfm");
            request.fw.onRequestEnd();
        }
        assertTrue( output contains "myteststring" );
        assertTrue( output contains "framework lifecycle trace" );
    }

    public void function testSetupTraceRenderHtml() {
        variables.fwExtended.onApplicationStart();
        var output = "";
        savecontent variable="output" {
            variables.fwExtended.onRequestEnd();
        }
        assertTrue( output contains "framework lifecycle trace" );
    }

    public void function testSetupTraceRenderData() {
        variables.fwExtended.onApplicationStart();
        variables.fwExtended.renderData( "text", "test" );
        var output = "";
        savecontent variable="output" {
            variables.fwExtended.onRequestEnd();
        }
        assertEquals( output, "custom trace render" );
    }

    public void function testRenderFunction() {
        request.fw.onApplicationStart();
        variables.fw.renderData().type( function( renderData ) {
            return {
                contentType = "text/html; charset=utf-8",
                output = "string",
                writer = function( out ) {
                    writeOutput( "my written " & out );
                }
            };
        } ).data( "myteststring" );
        var output = "";
        savecontent variable="output" {
            request.fw.onRequest("/index.cfm");
            request.fw.onRequestEnd();
        }
        assertTrue( output contains "my written string" );
        assertFalse( output contains "framework lifecycle trace" );
    }


}
