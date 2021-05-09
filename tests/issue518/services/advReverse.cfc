component displayname="advReverseService" extends="Reverse" accessors="true" output="false" {


	// PUBLIC METHODS
	public function configure() {
		getStackLog().log("configure");
		return this;
	}


	public function doWrap(string input) {
		getStackLog().log("doWrap");
		return doRear(doFront(arguments.input));
	}


	public function init() {
		// stackLog does not exist at this point.
		arrayAppend(request.callStack, "init");

		return super.init();
	}


	public function setStackLog(any stackLog) {
		// stackLog does not exist at this point.
		arrayAppend(request.callStack, "setStackLog");

		variables.stackLog = arguments.stackLog;
	}




	// PRIVATE METHODS
	private function doFront(string input) {
		getStackLog().log("doFront");
		return "front-" & arguments.input;
	}


	private function doRear(string input) {
		getStackLog().log("doRear");
		return arguments.input & "-rear";
	}
}
