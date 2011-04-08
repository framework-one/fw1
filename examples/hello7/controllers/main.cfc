component {
	
	public any function init( any fw ) {
		variables.fw = fw;
		return this;
	}
	
	public void function default( struct rc ) {
		variables.fw.setView( 'normal.index' );
	}
	
}