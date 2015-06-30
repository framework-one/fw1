component output="false" displayname="ReverseService" extends="Reverse"  {
	public function configure(){
		ArrayAppend(request.callstack, "configure");
		return this;
	}

	public function init(){
		ArrayAppend(request.callstack, "init");
		return this;
	}

	public function doWrap(String input){
		ArrayAppend(request.callstack, "doWrap");
		return doRear(doFront(arguments.input));
	}




	private function doFront(String input){
		ArrayAppend(request.callstack, "doFront");
		return "front-" & arguments.input;
	}

	private function doRear(String input){
		ArrayAppend(request.callstack, "doRear");
		return arguments.input & "-rear";
	}
}
