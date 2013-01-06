component extends="org.corfield.framework" {
	// Either put the org folder in your webroot or create a mapping for it!
	
	this.name = 'fw1-examples';
	this.sessionManagement = true;
	// FW/1 - configuration:
	variables.framework = {
		usingSubsystems = true,
		SESOmitIndex = true,
        trace = true
	};
	
	// pull in bean factory for hello8:
	public void function setupSubsystem( string subsystem ) {
		if ( subsystem == "hello8" ) {
			var bf = new hello8.model.ioc( "./hello8" );
			setSubsystemBeanFactory( subsystem, bf );
		}
	}
	
}
