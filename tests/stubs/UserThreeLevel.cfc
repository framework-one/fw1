component accessors = true {

	property name = username getters = true setters = true type = string;
	property name = isActive getters = true setters = true type = boolean;
	property name = contact getters = true setters = true type = stubs.Contact;


	public void function init()
	output = false hint = "constructor" {
		variables.username = "";
		variables.Contact = new Contact();
		variables.isActive = false;
	}
}