component output="false" extends="coldspring.aop.BeforeAdvice"{

	this.name = "before";
	function init(name="before"){
		this.name=name;
	}

	function before(method,args,target){
		ArrayAppend(request.callstack, this.name);
		arguments.args.input = "before" & arguments.args.input;
	}
}