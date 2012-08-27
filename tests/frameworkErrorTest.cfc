component extends="mxunit.framework.TestCase" {

    public void function setUp() {
        variables.fw = new org.corfield.framework();
        request.failureCount = 0;
        request.outputContent = "";
        injectMethod(variables.fw, this, "outputCapture", "writeOutputInternal");
        injectMethod(variables.fw, this, "exceptionCapture", "dumpException");
    }
    
    /**
	* Test with initialised framework - ensure error handler tries to render the main.error view
	*/
    public void function testError()
    {
        var exception = {
            type = "Testing",
            message = "Testing",
            detail = "Detail"
        };
        var event = "Test Event";
        variables.fw.onApplicationStart();
        variables.fw.onError(exception, event);   
        assertEquals(request.action, "main.error");
        assertTrue(request.outputContent contains "Unable to find a view for 'main.error' action.");
    }

    /**
    * Test with un-initialised framework - ensure internal error is not as prominent
    */        
    public void function testEarlyError()
    {        
        var exception = {
            type = "Testing",
            message = "Testing",
            detail = "Detail"
        };
        var event = "";       
        variables.fw.onError(exception, event);
        assertFalse(request.outputContent CONTAINS "Element FRAMEWORK.USINGSUBSYSTEMS is undefined in VARIABLES", "Didn't expect failure in early exception");
        assertTrue(request.outputContent CONTAINS "Exception occured before FW/1 was initialised", "Excepted message about early exception");        
    }
        
    private void function outputCapture( any content )
    {
        writeLog(text="Output #content#");
        request.outputContent &= arguments.content; 
    }      
    
    private void function exceptionCapture( any exception)
    {
        writeLog(text="Exception: #exception.message#");
        request.capturedException = arguments.exception;
    }
}