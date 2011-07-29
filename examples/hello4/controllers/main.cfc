component {
	
	function init( fw ) {
		variables.fw = fw;
	}
	
	function startDefault( rc ) {
		param name="rc.name" default="anonymous";
		variables.fw.service( "main.default", "data" ); // was implicit in 1.x 
	}
	
	function endDefault( rc ) {
		rc.name = rc.data;
	}
}