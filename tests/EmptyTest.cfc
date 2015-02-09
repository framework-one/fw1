component extends="mxunit.framework.TestCase" {

    function setup() {
        variables.emptyFactory = new framework.ioc( "" );
    }

    function shouldContainBeanFactory() {
        assertTrue( variables.emptyFactory.containsBean( "beanFactory" ) );
    }

    function shouldContainJustOneBean() {
        var info = variables.emptyFactory.getBeanInfo();
        assertEquals( 1, structCount( info.beaninfo ) );
        assertEquals( "beanfactory", structKeyList( info.beaninfo ) );
    }

}
