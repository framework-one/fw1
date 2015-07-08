component displayname="reverseService" extends="stringService" accessors="true" output="false" {


	public function doForward(string input) {
		//I double reverse a string... i.e. do nothing!
		getStackLogService().log("doForward");
		return reverse(reverse(arguments.input));	
	}


	public function doReverse(string input) {
		getStackLogService().log("doReverse");
		return reverse(arguments.input);
	}


	public function throwError() {
		//This is just to throw an error
		getStackLogService().log("throwError");
		throw "I AM AN EVIL ERROR YOU WANT TO TRAP!";
	}
}