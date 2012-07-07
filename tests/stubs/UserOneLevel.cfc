component accessors = true {


	property name = username getters = true setters = true type = string;
	property name = firstName getters = true setters = true type = string;
	property name = lastName getters = true setters = true type = string;
	property name = isActive getters = true setters = true type = boolean;

	public void function init()
	output = false hint = "constructor" {
		variables.username = "";
		variables.firstName = "";
		variables.lastName = "";
		variables.isActive = false;
	}
}