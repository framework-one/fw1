component extends="framework.one" {
	
	public void function setupTraceRender( string output = 'html' ) {
		if ( output == 'data' ) {
			writeOutput( 'custom trace render' );
		}
	}

}