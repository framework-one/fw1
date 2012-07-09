component accessors = true {

	property name = username getters = true setters = true type = string;
	property name = contact getters = true setters = true type = stubs.Contact;
	property name = isActive getters = true setters = true type = boolean;


	public void function init()
	output = false hint = "constructor" {
		variables.username = "";
		variables.Contact = new Contact();
	}
}