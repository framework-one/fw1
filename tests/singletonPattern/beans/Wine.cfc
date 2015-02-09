component accessors="true" {

	property instanceid;

	function init() {
		variables.instanceid = CreateUUID();
		return this;
	}

}
