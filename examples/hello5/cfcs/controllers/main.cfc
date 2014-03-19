component accessors="true" {
    property mainService;
    function init( fw ) {
        variables.fw = fw;
        return this;
    }
    function default( rc ) {
        param name="rc.name" default="anonymous";
        rc.name = variables.mainService.default( rc.name );
    }
}
