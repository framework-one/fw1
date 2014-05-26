component {
    function init( fw ) {
        variables.fw = fw;
        return this;
    }
    function default( rc ) {
        param name="rc.name" default="anonymous";
    }
    function submit( rc ) {
		// redirect and preserve all request context - could just specify
		// "name" to be preserved since we don't need action and submit
        variables.fw.redirect( "main.default", "all" );
    }
}
