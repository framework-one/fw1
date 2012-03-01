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
	* @type stubs.Contact
	*/
	property Contact;

	/**
	* @getters true
	* @setters true
	* @type Boolean
	*/
	property isActive;


	public void function ()
	output=false hint="constructor"{
		variables.username = "";
		variables.Contact = new stubs.Contact();
	}
}