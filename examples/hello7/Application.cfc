component extends="org.corfield.framework" {

    // this example uses the deprecated start/end actions
    variables.framework.suppressServiceQueue = false;
	
	public void function setupView() {
		arrayAppend( rc.lifecycle, "setupView() called" );
	}
	
}
