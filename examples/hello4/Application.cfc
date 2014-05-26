component extends="org.corfield.framework" accessors="true" {
	// autowire these properties:
	property foo;
	property bar;
	// setup (simple) bean factory:
	function setupApplication() {
		var bf = new framework.ioc( "beans,services" );
		setBeanFactory( bf );
	}
	// show that before/after have bean factory autowired:
	function before( rc ) {
		rc.greeting = variables.foo.greeting();
		rc.punctuation = variables.bar.punctuation();
	}
}
