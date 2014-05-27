component accessors=true {

    property string name;

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
