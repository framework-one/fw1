/**
* @accessors true
*/
component {
	/**
	* @getters true
	* @setters true
	* @type String
	*/
	property line1;

	/**
	* @getters true
	* @setters true
	* @type String
	*/
	property line2;

	/**
	* @getters true
	* @setters true
	* @type Numeric
	*/
	property zipCode;	

	public void function init()
	output=false hint="constructor"{
		variables.line1 = "";
		variables.line2 = "";
		variables.zipCode = "";
	}
}