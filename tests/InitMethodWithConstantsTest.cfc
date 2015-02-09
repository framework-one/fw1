component extends="mxunit.framework.TestCase" {

    function setup() {

        var constantInstance = new initMethod.Constant();
        var constants = { known = 42, booleanValue = true, constObj = constantInstance };

        variables.beanFactory = new framework.ioc( "/tests/initMethod", { constants = constants , initMethod = "configure"} );

    }

    function shouldHaveCalledConfigure () {
        var myService = beanFactory.getBean("myService");
        assertEquals( 42, myService.getResult());
    }

    function shouldNotConfigureConstants () {
        var constObj = beanFactory.getBean("constObj");

        assertFalse( constObj.getBooleanValue() );
        assertFalse( constObj.hasConfigureBeenCalled() );
    }

}
