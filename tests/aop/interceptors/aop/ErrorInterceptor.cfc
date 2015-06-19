component output="false" {
	
	this.name = "onError";
	function init(name="onError"){
		this.name=name;
	}

	function onError(method,args,target, error){
		ArrayAppend(request.callstack, this.name);
		
	}
}