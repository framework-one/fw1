component extends="mxunit.framework.TestCase" {

    function setup() {
        bf = new framework.ioc( "" );
    }

    function testReturnWiredTransient() {
        // issue #420
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

    function testTransientIsInjectedAsConstructorInjectionIntoTransient() {
        bf.declare( "ConstructorInjectedBean" ).instanceOf( "tests.issue408.NoDependancies" ).asTransient();
        bf.declare( "ConstructorDependancy" ).instanceOf( "tests.issue408.ConstructorDependancy" ).asTransient();
        
        var ConstructorDependancy = bf.getBean( "ConstructorDependancy" );
        assertTrue( ConstructorDependancy.isInjected() );
    }

    function testTransientIsNotInjectedAsSetterInjectionIntoTransient() {
        bf.declare( "SetterInjectedBean" ).instanceOf( "tests.issue408.NoDependancies" ).asTransient();
        bf.declare( "SetterDependancy" ).instanceOf( "tests.issue408.SetterDependancy" ).asTransient();
        
        var SetterDependancy = bf.getBean( "SetterDependancy" );
        assertFalse( SetterDependancy.isInjected() );
    }

    function testSingletonIsInjectedAsConstructorInjectionIntoTransient() {
        bf.declare( "ConstructorInjectedBean" ).instanceOf( "tests.issue408.NoDependancies" ).asSingleton();
        bf.declare( "ConstructorDependancy" ).instanceOf( "tests.issue408.ConstructorDependancy" ).asTransient();
        
        var ConstructorDependancy = bf.getBean( "ConstructorDependancy" );
        assertTrue( ConstructorDependancy.isInjected() );
    }

    function testSingletonIsInjectedAsSetterInjectionIntoTransient() {
        bf.declare( "SetterInjectedBean" ).instanceOf( "tests.issue408.NoDependancies" ).asSingleton();
        bf.declare( "SetterDependancy" ).instanceOf( "tests.issue408.SetterDependancy" ).asTransient();
        
        var SetterDependancy = bf.getBean( "SetterDependancy" );
        assertTrue( SetterDependancy.isInjected() );
    }

    function testTransientIsInjectedAsConstructorInjectionIntoSingleton() {
        bf.declare( "ConstructorInjectedBean" ).instanceOf( "tests.issue408.NoDependancies" ).asTransient();
        bf.declare( "ConstructorDependancy" ).instanceOf( "tests.issue408.ConstructorDependancy" ).asSingleton();
        
        var ConstructorDependancy = bf.getBean( "ConstructorDependancy" );
        assertTrue( ConstructorDependancy.isInjected() );
    }
    
    function testTransientIsNotInjectedAsSetterInjectionIntoSingleton() {
        bf.declare( "ConstructorInjectedBean" ).instanceOf( "tests.issue408.NoDependancies" ).asTransient();
        bf.declare( "SetterDependancy" ).instanceOf( "tests.issue408.SetterDependancy" ).asSingleton();
        
        var SetterDependancy = bf.getBean( "SetterDependancy" );
        assertFalse( SetterDependancy.isInjected() );
    }

    function testSingletonIsInjectedAsSetterInjectionIntoSingleton() {
        bf.declare( "SetterInjectedBean" ).instanceOf( "tests.issue408.NoDependancies" ).asSingleton();
        bf.declare( "SetterDependancy" ).instanceOf( "tests.issue408.SetterDependancy" ).asSingleton();
        
        var SetterDependancy = bf.getBean( "SetterDependancy" );
        assertTrue( SetterDependancy.isInjected() );
    }

    function testSingletonIsInjectedAsConstructorInjectionIntoSingleton() {
        bf.declare( "ConstructorInjectedBean" ).instanceOf( "tests.issue408.NoDependancies" ).asSingleton();
        bf.declare( "ConstructorDependancy" ).instanceOf( "tests.issue408.ConstructorDependancy" ).asSingleton();
        
        var ConstructorDependancy = bf.getBean( "ConstructorDependancy" );
        assertTrue( ConstructorDependancy.isInjected() );
    }

}
