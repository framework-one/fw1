<cfcomponent><cfscript>
	
	function init( fw ) {
		variables.fw = fw;
	}
	
	function default() {
		variables.fw.setView( 'normal.index' );
	}
	
</cfscript></cfcomponent>