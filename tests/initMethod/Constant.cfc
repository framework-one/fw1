component accessors="true" {

    property booleanValue;

    function init() {

        setBooleanValue(false);
        variables.configureCalled = false;

        return this;
    }

    function configure() {
        variables.configureCalled = true;
    }

    boolean function hasConfigureBeenCalled() {
        return variables.configurecalled;
    }

}