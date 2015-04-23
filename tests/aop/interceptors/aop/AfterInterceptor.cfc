component output="false" displayname="AfterInterceptor"  {
	
	this.name = "after";
	function init(name="after"){
		this.name=name;
	}

	function after(method,args,target){
		ArrayAppend(request.callstack, this.name);

		//how do we know if we have run it?

			
	}
}