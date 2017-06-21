component {

    function init( constructorInjectedBean ) {
        variables.constructorInjectedBean = constructorInjectedBean;
        return this;
    }

    function isInjected() {
        return structKeyExists( variables, "constructorInjectedBean" );
    }
}
