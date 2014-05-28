component output="false" displayname="AroundInterceptor"  {
	
	this.name = "around";
	function init(name="around"){
		this.name=name;
	}

	function around(method,args,target){
		ArrayAppend(request.callstack, this.name);

		return proceed(method,args,target);
	}

	function proceed(method,args,target){
		if(isLast()){
            // because ACF doesn't support direct invocation syntax :(
			return evaluate("target[method](argumentCollection=args)");
		}
		return "";
	}

	function isLast(){
		return this.last ? this.last : false;
	}

}
