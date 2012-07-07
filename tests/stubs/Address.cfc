component accessors = true{
	
	property name = line1 getters = true setters = true type = string;

	property name = line2 getters = true setters = true type = string;

	property name = zipCode getters = true setters = true type = string;	

	public void function init()
	output=false hint="constructor"{
		variables.line1 = "";
		variables.line2 = "";
		variables.zipCode = "";
	}
}