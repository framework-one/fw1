component extends="mxunit.framework.TestCase"{
	public void function setUp(){
		variables.fw = new org.corfield.framework();
	}

	public void function testPopulateFlatComponent(){
		var user = new stubs.userOneLevel();
		fail("no test written yet.");
	}

	public void function testComponentWithSingleChild(){
		fail("no test written yet.");
	}

	public void function testComponentWithManyChildren(){
		fail("no test written yet.");
	}
	
	private Struct function getOneLevelRC()
	output=false {
		return {username = "foobar", firstName="Homer", lastName="Simpson", isActive=true};
	}

	private Struct function getTwoLevelRC()
	output=false {
		return {username = "foobar", contact.firstName="Homer", contact.lastName="Simpson", isActive=true, contact.dateCreated="02/29/2012"};
	}

	private Struct function getThreeLevelRC()
	output=false {
		return {
				username = "foobar", 
				contact.firstName="Homer", 
				contact.lastName="Simpson", 
				contact.dateCreated="02/29/2012",
				isActive=true,
				contact.address.line1 = "123 Fake Street",
				contact.address.line2 = "Apt 12",
				contact.address.zip = "54232"
		};
	}
}