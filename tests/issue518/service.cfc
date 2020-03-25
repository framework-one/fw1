component displayname="service" accessors="true" output="false" {


	property name="stackLog";


	public function getServiceName() {
		return listLast(getMetadata(this));
	}


	public function init() {
		return this;
	}
}
