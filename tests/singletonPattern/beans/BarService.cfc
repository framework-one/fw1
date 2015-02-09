/** 
* Note that although this beanname matches the singletonpattern it is considered 
* a transient as it's in the beans folder
**/ 
component accessors="true" {

	property instanceid;

	function init() {
		variables.instanceid = CreateUUID();
		return this;
	}

}
