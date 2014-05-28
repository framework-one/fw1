component output="false" displayname="ReverseService"  {
	param name="request.callstack" default="#[]#";

	public function doReverse(String input){
		ArrayAppend(request.callstack, "doReverse");
		return Reverse(arguments.input);
	}

	public function doForward(String input){
		//I double reverse a string... i.e. do nothing!
		ArrayAppend(request.callstack, "doForward");
		return Reverse(Reverse(arguments.input));	
	}

	public function throwError(){
		//This is just to throw an error
		ArrayAppend(request.callstack, "throwError");
		throw("I AM AN EVIL ERROR YOU WANT TO TRAP!");
	}
}