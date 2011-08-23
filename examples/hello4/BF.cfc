component hint="I am a minimal bean factory to demonstrate property-based injection" {
	
	function init() {
		variables.foo = new beans.foo();
		variables.bar = new beans.bar();
		return this;
	}
	
	boolean function containsBean( name ) {
		return name == "foo" || name == "bar";
	}
	
	function getBean( name ) {
		return name == "foo" ? variables.foo : variables.bar;
	}
	
}