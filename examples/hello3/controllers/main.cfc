component {
	
	function init( fw ) {
		variables.fw = fw;
	}
	
	function default( rc ) {
		variables.fw.service("name.default","name");
	}
	
	function endDefault( rc ) {
		rc.captured = variables.fw.view("main/capture");
	}
}
