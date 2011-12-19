component {
	
	public any function init( any fw ) {
		variables.fw = fw;
		return this;
	}
	
	public void function startDefault( struct rc ) {
		rc.lifecycle = [ "startDefault() called" ];
		variables.fw.setView( 'normal.index' );
		if ( structKeyExists( rc, "donotcatchexception" ) ) variables.fw.abortController();
		try {
			variables.fw.abortController();
		} catch ( any e ) {
			arrayAppend( rc.lifecycle, "caught " & e.type & ":" & e.message );
		}
		arrayAppend( rc.lifecycle, "should not execute unless we catch the exception" );
	}
	
	public void function endDefault( struct rc ) {
		arrayAppend( rc.lifecycle, "endDefault() should not be called" );
	}
	
}