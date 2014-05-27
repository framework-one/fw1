component extends="mxunit.framework.TestCase" {
	
	function setup() {
		transients = ['BarService','Beer','BeerFactory','Wine','CoffeeFoo','PizzaFoo'];
		singletons = ['Drinks','Tea','Burger','FoodFactory'];
		
		variables.factory = new framework.ioc( "/tests/transientPattern", { transientPattern = ".+(Foo)$" } );
	}
		
	function checkForSingletons( required beanname ) dataprovider="singletons" {
		assertTrue( variables.factory.containsBean( arguments.beanname ) );
		assertTrue( variables.factory.isSingleton( arguments.beanname ) );
		instanceA = variables.factory.getBean( arguments.beanname );
		instanceB = variables.factory.getBean( arguments.beanname );
		assertSame( instanceA, instanceB );
	}
		
	function checkForTransients( beanname ) dataprovider="transients" {
		//assertTrue( variables.factory.containsBean( beanname ) );
		assertFalse( variables.factory.isSingleton( beanname ) );
		instanceA = variables.factory.getBean( arguments.beanname );
		instanceB = variables.factory.getBean( arguments.beanname );
		assertNotSame( instanceA, instanceB );
	}
}
