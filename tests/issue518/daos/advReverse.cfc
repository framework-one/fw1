component displayname="advReverseService" extends="tests.issue518.services.Reverse" accessors="true" output="false" {


	// PUBLIC METHODS
	public function configure() {
		getStackLog().log("wrong-configure");
		return this;
	}


	public function doWrap(string input) {
		getStackLog().log("wrong-doWrap");
		return doRear(doFront(arguments.input));
	}


	public function init() {
		// stackLog does not exist at this point.
		arrayAppend(request.callStack, "wrong-init");

		return super.init();
	}


	public function setStackLog(any stackLog) {
		// stackLog does not exist at this point.
		arrayAppend(request.callStack, "wrong-setStackLog");

		variables.stackLog = arguments.stackLog;
	}




	// PRIVATE METHODS
	private function doFront(string input) {
		getStackLog().log("wrong-doFront");
		return "front-" & arguments.input;
	}


	private function doRear(string input) {
		getStackLog().log("wrong-doRear");
		return arguments.input & "-rear";
	}
}
