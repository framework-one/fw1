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
	
	// pull in bean factory for each subsystem:
	public void function setupSubsystem( string subsystem ) {
        var bf = new framework.ioc( "./" & subsystem );
        bf.addBean( "fw", this ); // so controllers can be init'd with fw
        setSubsystemBeanFactory( subsystem, bf );
	}
	
}
