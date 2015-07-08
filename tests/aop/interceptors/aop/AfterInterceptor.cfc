component displayname="AfterInterceptor" extends="interceptor" accessors="true" output="false" {
	

	function init(name="after") {
		this.name=name;
	}


	function after(target, method, args, result) {
		getStackLogService().log(this.name);

		// Demonstrate that we can alter the result.
		if (findNoCase("alter", this.name) && structKeyExists(arguments, "result") && !isNull(arguments.result))
		{
			return arguments.result & "," & this.name;
		}	
	}
}