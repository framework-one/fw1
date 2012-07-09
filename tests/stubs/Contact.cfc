component accessors = true {

	property name = firstName getters = true setters = true type = string;
	property name = lastName getters = true setters = true type = string;
	property name = dateCreated getters = true setters = true type = date;
	property name =  address getters = true setters = true type = stubs.Address;

	public void function init()
	output = false hint = "constructor" {
		variables.firstName = "";
		variables.lastName = "";

		variables.Address = new Address();
		//intentionally not initing date created
	}
}