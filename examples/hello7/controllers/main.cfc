component {
	
	public any function init( any fw ) {
		variables.fw = fw;
		return this;
	}
	
	public void function default( struct rc ) {
		rc.lifecycle = [ "default() called" ];
		variables.fw.setView( 'normal.index' );
		if ( structKeyExists( rc, "donotcatchexception" ) ) variables.fw.abortController();
		try {
			variables.fw.abortController();
		} catch ( any e ) {
			arrayAppend( rc.lifecycle, "caught " & e.type & ":" & e.message );
		}
		arrayAppend( rc.lifecycle, "should not execute unless we catch the exception" );
	}
	
}
