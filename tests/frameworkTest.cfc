component extends="mxunit.framework.TestCase"{
	public void function setUp(){
		variables.fw = new org.corfield.framework();
	}

	public void function testPopulateFlatComponent(){
		var user = new stubs.userOneLevel();
		request.context = getOneLevelRC();

		variables.fw.populate(user);

		assertEquals(request.context.username,user.getUserName());
		assertEquals(request.context.firstName,user.getFirstName());
		assertEquals(request.context.lastName,user.getLastName());
		assertEquals(request.context.isActive,user.getIsActive());
	}

	public void function testPopulateFlatComponentWithKeys(){
		var user = new stubs.userOneLevel();
		request.context = getOneLevelRC();

		variables.fw.populate(user,"username,firstname");

		assertEquals(request.context.username,user.getUserName());
		assertEquals(request.context.firstName,user.getFirstName());
		assertEquals("",user.getLastName());
		assertEquals(false,user.getIsActive());
	}

	public void function testComponentWithSingleChild(){
		var user = new stubs.userTwoLevel();
		request.context = getTwoLevelRC();

		variables.fw.populate(user);

		assertEquals(request.context.username,user.getUserName());
		assertEquals(request.context.firstName,user.getContact().getFirstName());
		assertEquals(request.context.lastName,user.getContact().getLastName());
		assertEquals(request.context.isActive,user.getContact().getIsActive());
	}

	public void function testComponentWithManyChildren(){
		var user = new stubs.userThreeLevel();
		request.context = getThreeLevelRC();

		variables.fw.populate(user);

		assertEquals(request.context.username,user.getUserName());
		assertEquals(request.context.firstName,user.getContact().getFirstName());
		assertEquals(request.context.lastName,user.getContact().getLastName());
		assertEquals(request.context.isActive,user.getContact().getIsActive());
		assertEquals(request.context.line1,user.getContact().getAddress().getFirstName());
		assertEquals(request.context.line2,user.getContact().getAddress().getLastName());
		assertEquals(request.context.zip,user.getContact().getAddress().getIsActive());
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