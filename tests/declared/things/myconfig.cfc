component accessors=true {

    property string name;
    property dftname default="default";

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
