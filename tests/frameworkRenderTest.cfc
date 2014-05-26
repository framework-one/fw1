component extends="mxunit.framework.TestCase" {

    public void function setUp() {
        variables.fw = new org.corfield.framework();
        variables.fw.enableTracing = _enableTracing;
        variables.fw.enableTracing();
        request.fw = new org.corfield.framework();
        request.fw.enableTracing = _enableTracing;
        request.fw.enableTracing();
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

}
