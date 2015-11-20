component accessors=true {

    property string name;
    property name="dftname" default="default";
    // not legal syntax: property dftname="default";
    // legal syntax, doesn't create setter: property string dftname="default";

    function init( string data = "none" ) {
        setConfig( data );
    }

    function setConfig( string config ) {
        variables.config = config;
    }

    function getConfig() {
        return variables.config;
    }

}
