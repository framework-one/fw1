component extends="mxunit.framework.TestCase" {

	private any function clearFrameworkFromRequest () {
        structDelete(request, "_fw1");
	}

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
