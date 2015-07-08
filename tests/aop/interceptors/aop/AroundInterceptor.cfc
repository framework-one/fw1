component displayname="AroundInterceptor" extends="interceptor" accessors="true" output="false" {
	

	function init(name="around") {
		this.name=name;
	}


	function around(target, method, args) {
		getStackLogService().log(this.name);

		local.result = proceed(arguments.target, arguments.method, arguments.args);

		// This runs on 'set...' methods as well for properties.  Limit to simple result calls.
		if (structKeyExists(local, "result") && !isNull(local.result) && isSimpleValue(local.result))
		{
			return this.name & "," & local.result & "," & this.name;
		}
		else
		{
			writeDump(var = isNull(arguments.target));
			writeDump(var = isNull(arguments.target.getStackLogService()));
			writeDump(var = arguments.method);
			writeDump(var = structKeyList(arguments.target), abort = true);
		}
	}
}