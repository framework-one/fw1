component displayname="stackLogService" extends="service" output="false" {


	public function init() {
		if (!structKeyExists(request, "callStack"))
		{
			request["callStack"] = [];
		}

		return super.init();
	}


	public function log(string message) {
		arrayAppend(request.callStack, message);
	}
}