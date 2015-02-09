component extends="framework.one" {
	// Either put the framework folder in your webroot or create a mapping for it!
	
	this.name = 'fw1-examples';
	this.sessionManagement = true;
	// FW/1 - configuration:
	variables.framework = {
		usingSubsystems = true,
		SESOmitIndex = true,
        diLocations = "model, controllers, beans, services", // to account for the variety of D/I locations in our examples
        // that allows all our subsystems to automatically have their own bean factory with the base factory as parent
        trace = true
	};
	
}
