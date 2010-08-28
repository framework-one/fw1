<cfcomponent extends="org.corfield.framework"><cfscript>
	// Either put the org folder in your webroot or create a mapping for it!
	
	this.name = 'fw1-examples';
	this.sessionManagement = true;
	// FW/1 - configuration:
	variables.framework = structNew();
	variables.framework.usingSubsystems = true;
	
</cfscript></cfcomponent>