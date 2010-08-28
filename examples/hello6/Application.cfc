<cfcomponent extends="org.corfield.framework"><cfscript>
	this.sessionManagement = true;
	variables.framework = structNew();
	// reduce contexts to 1 to remove fw1pk from redirect URL:
	variables.framework.maxNumContextsPreserved = 1;
</cfscript></cfcomponent>