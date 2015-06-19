component output="false" displayname="AroundInterceptor" {
	
	this.name = "around";
	function init(name="around"){
		this.name=name;
	}

	function around(target, method, args){
		ArrayAppend(request.callstack, this.name);

		local.result = proceed(arguments.target, arguments.method, arguments.args);

		if (structKeyExists(local, "result") && !isNull(local.result))
		{
			return this.name & "," & local.result & "," & this.name;
		}
	}
}
