component extends="mxunit.framework.TestCase" {

    public void function setUp() {
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
        variables.fw.renderData( "text", "test" );
        var output = "";
        savecontent variable="output" {
            request.fw.onRequestEnd();
        }
        assertFalse( output contains "framework lifecycle trace" );
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


}
