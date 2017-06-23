component {
    function init() {
        return this;
    }

    function isInjected() {
        return structKeyExists( variables, "SetterInjectedBean" );
    }

    function setSetterInjectedBean( SetterInjectedBean ) {
        variables.SetterInjectedBean = SetterInjectedBean;
    }
}
