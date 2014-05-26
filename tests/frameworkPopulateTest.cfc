component extends="mxunit.framework.TestCase" {

	public void function setUp() {
		variables.fw = new org.corfield.framework();
		clearFW1MetaData();
	}

	public void function testPopulateFlatComponent() {
		var user = new stubs.UserOneLevel();
		request.context = getOneLevelRC();

		variables.fw.populate( user );

		assertEquals( request.context.username,user.getUserName() );
		assertEquals( request.context.firstName,user.getFirstName() );
		assertEquals( request.context.lastName,user.getLastName() );
		assertEquals( request.context.isActive,user.getIsActive() );
	}

	public void function testPopulateFlatComponentWithKeys() {
		var user = new stubs.UserOneLevel();
		request.context = getOneLevelRC();

		variables.fw.populate( cfc=user, keys="username,firstname", deep=true );

		assertEquals( request.context.username, user.getUserName() );
		assertEquals( request.context.firstName, user.getFirstName() );
		assertEquals( "", user.getLastName() );
		assertEquals( false, user.getIsActive() );
	}

	public void function testPopulatePropsFlatComponent() {
		var user = new stubs.UserOneLevel();
		request.context = getThreeLevelRC();
        var props = getOneLevelRC();

		variables.fw.populate( cfc=user, properties=props );

		assertEquals( props.username,user.getUserName() );
		assertEquals( props.firstName,user.getFirstName() );
		assertEquals( props.lastName,user.getLastName() );
		assertEquals( props.isActive,user.getIsActive() );
	}

	public void function testPopulatePropsFlatComponentWithKeys() {
		var user = new stubs.UserOneLevel();
		request.context = getThreeLevelRC();
        var props = getOneLevelRC();

		variables.fw.populate( cfc=user, keys="username,firstname", deep=true,
                               properties=props );

		assertEquals( props.username, user.getUserName() );
		assertEquals( props.firstName, user.getFirstName() );
		assertEquals( "", user.getLastName() );
		assertEquals( false, user.getIsActive() );
	}

	public void function testPopulateChildComponentWithKeys() {
		var user = new stubs.UserTwoLevel();
		request.context = getTwoLevelRC();

		variables.fw.populate( cfc=user, keys="contact.firstName,username", deep=true );

		assertEquals( request.context.username, user.getUserName() );
		assertEquals( request.context[ "contact.firstName" ], user.getContact().getFirstName() );
		assertEquals( "", user.getContact().getLastName() );
	}

	public void function testPopulateChildComponentWithTrustKeys() {
		var user = new stubs.UserTwoLevel();
		request.context = getTwoLevelRC();

		variables.fw.populate( cfc=user, trustKeys=true );

		assertEquals( request.context.username,user.getUserName() );
		assertEquals( request.context[ "contact.firstName" ], user.getContact().getFirstName() );
		assertEquals( request.context[ "contact.lastName" ], user.getContact().getLastName() );
	}

	public void function testComponentWithSingleChild() {
		var user = new stubs.UserTwoLevel();
		request.context = getTwoLevelRC();

		variables.fw.populate( cfc=user, deep=true );

		assertEquals( request.context.username,user.getUserName() );
		assertEquals( request.context[ "contact.firstName" ], user.getContact().getFirstName() );
		assertEquals( request.context[ "contact.lastName" ], user.getContact().getLastName() );
		assertEquals( request.context[ "contact.dateCreated" ], user.getContact().getDateCreated() );
	}

	public void function testComponentWithSingleChildAndDeepFalse() {
		var user = new stubs.UserTwoLevel();
		request.context = getTwoLevelRC();

		variables.fw.populate( cfc=user );

		assertEquals( request.context.username,user.getUserName() );
		assertEquals( "",user.getContact().getFirstName() );
		assertEquals( "",user.getContact().getLastName() );
		assertEquals( true,user.getIsActive() );
	}

	public void function testComponentWithManyChildren() {
		var user = new stubs.UserThreeLevel();
		request.context = getThreeLevelRC();

		variables.fw.populate(cfc=user,deep=true);

		assertEquals( request.context.username, user.getUserName() );
		assertEquals( request.context[ "contact.firstName" ], user.getContact().getFirstName() );
		assertEquals( request.context[ "contact.lastName" ], user.getContact().getLastName() );
		assertEquals( request.context.isActive, user.getIsActive() );
		assertEquals( request.context[ "contact.address.line1" ], user.getContact().getAddress().GetLine1() );
		assertEquals( request.context[ "contact.address.line2" ], user.getContact().getAddress().GetLine2() );
		assertEquals( request.context[ "contact.address.zipCode" ], user.getContact().getAddress().GetZipCode() );
	}

	public void function testComponentWithManyChildrenAndTrustKeys() {
		var user = new stubs.UserThreeLevel();
		request.context = getThreeLevelRC();

		variables.fw.populate( cfc=user, deep=true, trustKeys=true );

		assertEquals( request.context.username, user.getUserName() );
		assertEquals( request.context[ "contact.firstName"], user.getContact().getFirstName() );
		assertEquals( request.context[ "contact.lastName"], user.getContact().getLastName() );
		assertEquals( request.context.isActive, user.getIsActive() );
		assertEquals( request.context[ "contact.address.line1"], user.getContact().getAddress().GetLine1() );
		assertEquals( request.context[ "contact.address.line2"], user.getContact().getAddress().GetLine2() );
		assertEquals( request.context[ "contact.address.zipCode"], user.getContact().getAddress().GetZipCode() );
	}

	public void function testComponentWithManyChildrenPassInKeys() {
		var user = new stubs.UserThreeLevel();
		request.context = getThreeLevelRC();

		variables.fw.populate( cfc=user, deep=true, keys = "contact.firstName,contact.address.line1,username" );

		assertEquals( request.context.username, user.getUserName() );
		assertEquals( request.context[ "contact.firstName" ], user.getContact().getFirstName() );
		assertEquals( "", user.getContact().getLastName() );
		assertEquals( false, user.getIsActive() );
		assertEquals( request.context[ "contact.address.line1" ], user.getContact().getAddress().GetLine1() );
		assertEquals( "", user.getContact().getAddress().GetLine2() );
		assertEquals( "", user.getContact().getAddress().GetZipCode() );
	}

	public void function testPropsComponentWithManyChildrenPassInKeys() {
		var user = new stubs.UserThreeLevel();
		request.context = getOneLevelRC();
        var props = getThreeLevelRC();

		variables.fw.populate( cfc=user, deep=true, keys = "contact.firstName,contact.address.line1,username", properties=props );

		assertEquals( props.username, user.getUserName() );
		assertEquals( props[ "contact.firstName" ], user.getContact().getFirstName() );
		assertEquals( "", user.getContact().getLastName() );
		assertEquals( false, user.getIsActive() );
		assertEquals( props[ "contact.address.line1" ], user.getContact().getAddress().GetLine1() );
		assertEquals( "", user.getContact().getAddress().GetLine2() );
		assertEquals( "", user.getContact().getAddress().GetZipCode() );
	}

	private Struct function getOneLevelRC()
	output=false {
		return { username = "foobar", firstName="Homer", lastName="Simpson", isActive=true };
	}

	private Struct function getTwoLevelRC()
	output=false {
		return { username = "foobar", "contact.firstName" = "Homer", "contact.lastName" = "Simpson", isActive = true, "contact.dateCreated" = "02/29/2012" };
	}

	private Struct function getThreeLevelRC()
	output=false {
		return {
				username = "foobar", 
				"contact.firstName" = "Homer", 
				"contact.lastName" = "Simpson", 
				"contact.dateCreated" = "02/29/2012",
				isActive = true,
				"contact.address.line1" = "123 Fake Street",
				"contact.address.line2" = "Apt 12",
				"contact.address.zipCode" = "54232"
		};
	}

	private void function clearFW1MetaData()
	output=false hint=""{
		var cfcs = {};

		cfcs[ "stubs.Address" ] =  getMetaData( new stubs.Address() );

		cfcs[ "stubs.Contact" ] =  getMetaData( new stubs.Contact() );
		cfcs[ "stubs.UserOneLevel" ] =  getMetaData( new stubs.UserOneLevel() );
		cfcs[ "stubs.UserTwoLevel" ] =  getMetaData( new stubs.UserTwoLevel() );
		cfcs[ "stubs.UserThreeLevel" ] =  getMetaData( new stubs.UserThreeLevel() );
		
		for(cfc in cfcs){
			if ( structKeyExists( cfcs[ cfc ], '__fw1_setters' ) ) {
				structDelete( cfcs[ cfc ], "__fw1_setters" );
			}
		}
	}
}
