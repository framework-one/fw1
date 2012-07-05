/**
* @accessors true
*/
component {
	/**
	* @getters true
	* @setters true
	* @type String
	*/
	property firstName;

	/**
	* @getters true
	* @setters true
	* @type String
	*/
	property lastName;

	/**
	* @getters true
	* @setters true
	* @type Date
	*/
	property dateCreated;

	/**
	* @getters true
	* @setters true
	* @type stubs.Address
	*/
	property Address;

	public void function init()
	output=false hint="constructor"{
		variables.firstName = "";
		variables.lastName = "";

		variables.Address = new stubs.Address();
		//intentionally not initing date created
	}
}