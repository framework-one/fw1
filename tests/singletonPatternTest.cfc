component extends="mxunit.framework.TestCase" {

	function setup() {
		/**
		* Note that although 'BeerFactory' and 'BarService' match the singletonpattern
		* they are considered transients as in the beans folder
		**/
		transients = ['BarService','Beer','BeerFactory','Wine','Coffee','Tea','Burger','Pizza'];
		singletons = ['DrinksService','FoodFactory'];

		variables.factory = new framework.ioc( "/tests/singletonPattern", { singletonPattern = ".+(Service|Factory)$" } );
	}

	function testForSingletons() {
		for ( var s in singletons ) checkForSingletons( s );
	}
	function checkForSingletons( required beanname ) dataprovider="singletons" {
		assertTrue( variables.factory.containsBean( arguments.beanname ) );
		assertTrue( variables.factory.isSingleton( arguments.beanname ) );
		instanceA = variables.factory.getBean( arguments.beanname );
		instanceB = variables.factory.getBean( arguments.beanname );
		assertSame( instanceA, instanceB );
	}

	function testForTransients() {
		for ( var t in transients ) checkForTransients( t );
	}
	function checkForTransients( beanname ) dataprovider="transients" {
		//assertTrue( variables.factory.containsBean( beanname ) );
		assertFalse( variables.factory.isSingleton( beanname ) );
		instanceA = variables.factory.getBean( arguments.beanname );
		instanceB = variables.factory.getBean( arguments.beanname );
		assertNotSame( instanceA, instanceB );
	}

    function testPatternsAreExclusive() {
        try {
            var bad = new framework.ioc( '', { singletonPattern = '', transientPattern = '' } );
            fail( 'Both arguments were allowed' );
        } catch ( any e ) {
            assertEquals( 'singletonPattern and transientPattern are mutually exclusive', e.message );
        }
    }

}
