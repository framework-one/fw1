component displayname="reverseService" extends="tests.issue518.string" accessors="true" output="false" {


	public function doForward(string input) {
		//I double reverse a string... i.e. do nothing!
		getStackLog().log("doForward");
		return reverse(reverse(arguments.input));
	}


	public function doReverse(string input) {
		getStackLog().log("doReverse");
		return reverse(arguments.input);
	}


	public function throwError() {
		//This is just to throw an error
		getStackLog().log("throwError");
		throw "I AM AN EVIL ERROR YOU WANT TO TRAP!";
	}
}
