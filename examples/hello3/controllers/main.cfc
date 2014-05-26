component accessors="true" {

    property nameService;
	
	function init( fw ) {
		variables.fw = fw;
        return this;
	}
	
	function default( rc ) {
		rc.name = variables.nameService.default( argumentCollection = rc );
		rc.captured = variables.fw.view("main/capture");
	}
}
