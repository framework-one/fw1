// Functional interface to FW/1's buildURL() function
component {

    function init( fw ) {
        variables.fw = fw;
        return this;
    }

    function apply( arg ) {
        return variables.fw.buildURL( arg );
    }

}
