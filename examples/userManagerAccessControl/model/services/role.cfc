component {

    function init( beanFactory ) {
        variables.beanFactory = beanFactory;
        variables.roles = { };

		// since services are cached role data will be persisted
		// ideally, this would be saved elsewhere, e.g. database

		// FIRST
        var role = variables.beanFactory.getBean("roleBean");
		role.setId("1");
		role.setName("Admin");

		variables.roles[role.getId()] = role;

		// SECOND
		role = variables.beanFactory.getBean("roleBean");
		role.setId("2");
		role.setName("User");

		variables.roles[role.getId()] = role;

        return this;
    }

    function get( string id ) {
        var result = 0;
        if ( len( id ) && structKeyExists( variables.roles, id ) ) {
            result = variables.roles[ id ];
        } else {
            result = variables.beanFactory.getBean( "roleBean" );
        }
        return result;
    }

    function list() {
        return variables.roles;
    }

}
