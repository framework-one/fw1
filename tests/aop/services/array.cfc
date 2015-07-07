component displayname="arrayService" extends="service" accessors="true" output="false" {


	public array function doListToArray(string list) {
		//I double reverse a string... i.e. do nothing!
		getStackLogService().log("doListToArray");
		return listToArray(arguments.list);	
	}
}