component output="false" accessors="true" {

	property username;
	property userid;
	public any function init( numeric userid = 0, string username = "defaultuser" ) {
		setusername( arguments.username );
		setuserid( arguments.userid );
		return this;
	}
}