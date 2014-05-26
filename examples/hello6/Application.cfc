component extends="org.corfield.framework" {
	this.sessionManagement = true;
	// reduce contexts to 1 to remove fw1pk from redirect URL:
	variables.framework = { maxNumContextsPreserved = 1 };
}
