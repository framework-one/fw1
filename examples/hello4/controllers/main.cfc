component accessors="true" {
	
	function init( fw ) {
		variables.fw = fw;
	}
	
	function startDefault( rc ) {
		param name="rc.name" default="anonymous";
		
		// we default the greeting / punctuation so that when this example is run without
		// a bean factory, we still have values in these variables:
		param name="rc.greeting" default="Hi";
		param name="rc.punctuation" default=".";

		variables.fw.service( "main.default", "data" ); // was implicit in 1.x 
	}
	
	function endDefault( rc ) {
		rc.name = rc.data;
	}
}