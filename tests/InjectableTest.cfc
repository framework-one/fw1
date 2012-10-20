component extends="mxunit.framework.TestCase" {

    private any function getVariablesScope( any cfc ) {
        cfc.__$$fetchVariables = returnVariablesScope;
        var vars = cfc.__$$fetchVariables();
        structDelete( cfc, "__$$fetchVariables" );
        return vars;
    }

    private any function returnVariablesScope() {
        return variables;
    }

}
