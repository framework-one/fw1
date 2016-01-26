component extends="mxunit.framework.TestCase" {

    function shouldReturnWiredTransient() {
        // issue #420
        var bf = new framework.ioc( "" );
        bf.declareBean("transient", "tests.issue420.transient", false);
        bf.declareBean("singleton", "tests.issue420.singleton", true);

        assertTrue( bf.containsBean( "transient" ) );
        assertFalse( bf.isSingleton( "transient" ) );

        var singleton = bf.getBean( "transient" ).getSingleton();
        assertTrue( isValid( "component", singleton ), "should return the singleton instance on the 1st call" );
        assertTrue( isValid( "component", singleton.getBeanFactory() ), "should return ioc instance on the 1st call" );

        // call again to check subsequent calls return wired transient
        singleton = bf.getBean( "transient" ).getSingleton();
        assertTrue( isValid( "component", singleton ), "should return the singleton instance on the 2nd call" );
        assertTrue( isValid( "component", singleton.getBeanFactory() ), "should return ioc instance on the 2nd call" );
    }

}
