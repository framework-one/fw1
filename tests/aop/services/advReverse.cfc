component displayname="advReverseService" extends="Reverse" accessors="true" output="false" {


	// PUBLIC METHODS
	public function configure() {
		getStackLogService().log("configure");
		return this;
	}


	public function doWrap(string input) {
		getStackLogService().log("doWrap");
		return doRear(doFront(arguments.input));
	}


	public function init() {
		// stackLogService does not exist at this point.
		arrayAppend(request.callStack, "init");

		return super.init();
	}


	public function setStackLogService(any stackLogService) {
		// stackLogService does not exist at this point.
		arrayAppend(request.callStack, "setStackLogService");

		variables.stackLogService = arguments.stackLogService;
	}




	// PRIVATE METHODS
	private function doFront(string input) {
		getStackLogService().log("doFront");
		return "front-" & arguments.input;
	}


	private function doRear(string input) {
		getStackLogService().log("doRear");
		return arguments.input & "-rear";
	}
}
