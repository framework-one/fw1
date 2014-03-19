component accessors="true" {

    property formatterService;
	
	public any function init( fw ) {
		variables.fw = fw;
		return this;
	}
	
	public void function default( rc ) {
		rc.today = variables.formatterService.longdate( now() );
	}
	
}
