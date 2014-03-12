component accessors="true" {

    property mainService;
	
	function init( fw ) {
		variables.fw = fw;
	}
	
	function default( rc ) {
		param name="rc.name" default="anonymous";
		
		// we default the greeting / punctuation so that when this example is run without
		// a bean factory, we still have values in these variables:
		param name="rc.greeting" default="Hi";
		param name="rc.punctuation" default=".";

        rc.name = variables.mainService.default( rc.name );
	}

}
