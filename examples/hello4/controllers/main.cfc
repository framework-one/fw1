component accessors="true" {
	
	// these are injected when hello4 is run standalone because it sets up a bean factory
	// when hello4 is run as part of the subsystem example, it's Application.cfc is not
	// used and therefore the bean factory is not created...
	property foo;
	property bar;
	
	function init( fw ) {
		variables.fw = fw;
	}
	
	function startDefault( rc ) {
		param name="rc.name" default="anonymous";
		
		// we default the greeting / punctuation so that when this example is run without
		// a bean factory, we still have values in these variables:
		param name="rc.greeting" default="Hi";
		param name="rc.punctuation" default=".";
		
		// if the properties were injected, use them to get the data:
		if ( structKeyExists( variables, "foo" ) ) rc.greeting = variables.foo.greeting();
		if ( structKeyExists( variables, "bar" ) ) rc.punctuation = variables.bar.punctuation();

		variables.fw.service( "main.default", "data" ); // was implicit in 1.x 
	}
	
	function endDefault( rc ) {
		rc.name = rc.data;
	}
}