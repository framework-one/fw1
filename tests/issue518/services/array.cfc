component displayname="arrayService" extends="tests.issue518.service" accessors="true" output="false" {


	public array function doListToArray(string list) {
		//I double reverse a string... i.e. do nothing!
		getStackLog().log("doListToArray");
		return listToArray(arguments.list);
	}
}
