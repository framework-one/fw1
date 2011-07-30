component {
	
	function init( fw ) {
		variables.fw = fw;
	}
	
	function startDefault( rc ) {
		param name="rc.name" default="anonymous";
		variables.fw.service("main.default","data");
	}
	
	function endDefault( rc ) {
		rc.captured = variables.fw.view("main/capture");
	}
}