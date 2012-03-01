/**
* @accessors true
*/
component {

	/**
	* @getters true
	* @setters true
	* @type String
	*/
	property username;

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
	* @type Boolean
	*/
	property isActive;

	public void function init()
	output=false hint="constructor"{
		variables.username = "";
		variables.firstName = "";
		variables.lastName = "";
		variables.isActive = false;
	}
}