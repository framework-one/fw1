component output="false" displayname="AfterInterceptor"  {
	
	this.name = "after";
	function init(name="after"){
		this.name=name;
	}

	function after(target, method, args, result){
		ArrayAppend(request.callstack, this.name);

		//how do we know if we have run it?
		if (findNoCase("alter", this.name) && structKeyExists(arguments, "result") && !isNull(arguments.result))
		{
			return arguments.result & "," & this.name;
		}	
	}
}