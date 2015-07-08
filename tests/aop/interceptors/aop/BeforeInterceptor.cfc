component displayname="BeforeInterceptor" extends="interceptor" accessors="true" output="false" {


	function init(name="before") {
		this.name=name;
	}


	function before(target, method, args) {
		getStackLogService().log(this.name);

		translateArgs(target, method, args, true);

		// Demonstrate that we can alter the arguments before the method call.
		if (structKeyExists(arguments.args, "input"))
		{
			arguments.args.input = "before" & arguments.args.input;
		}
	}
}