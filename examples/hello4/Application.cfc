component extends="framework.one" accessors="true" {

	// autowire these properties:
	property foo;
	property bar;

    variables.framework.diLocations = "beans, services";

	// show that before/after have bean factory autowired:
	function before( rc ) {
		rc.greeting = variables.foo.greeting();
		rc.punctuation = variables.bar.punctuation();
	}
}
