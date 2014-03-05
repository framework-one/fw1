component accessors=true {

    variables.users = { };
    variables.nextId = 0;

    function init( departmentService, beanFactory ) {
        variables.departmentService = departmentService;
        variables.beanFactory = beanFactory;

		var user = "";
		
		// since services are cached user data we'll be persisted
		// ideally, this would be saved elsewhere, e.g. database
		
		// FIRST
		user = beanFactory.getBean( "userBean" );
		user.setId("1");
		user.setFirstName("Curly");
		user.setLastName("Stooge");
		user.setEmail("curly@stooges.com");
		user.setDepartmentId("1");
		user.setDepartment(departmentService.get("1"));
		
		variables.users[user.getId()] = user;
		
		// SECOND
		user = beanFactory.getBean( "userBean" );
		user.setId("2");
		user.setFirstName("Larry");
		user.setLastName("Stooge");
		user.setEmail("larry@stooges.com");
		user.setDepartmentId("2");
		user.setDepartment(departmentService.get("2"));
		
		variables.users[user.getId()] = user;
		
		// THIRD
		user = beanFactory.getBean( "userBean" );
		user.setId("3");
		user.setFirstName("Moe");
		user.setLastName("Stooge");
		user.setEmail("moe@stooges.com");
		user.setDepartmentId("3");
		user.setDepartment(departmentService.get("3"));
		
		variables.users[user.getId()] = user;
		
		// BEN
		variables.nextid = 4;
	
        return this;
    }

    function delete( string id ) {
        structDelete( variables.users, id );
    }

    function get( string id ) {
        var result = "";
        if ( len( id ) && structKeyExists( variables.users, id ) ) {
            result = variables.users[ id ];
        } else {
            result = variables.beanFactory.getBean( "userBean" );
        }
        return result;
    }

    function list() {
        return variables.users;
    }

    function save( user ) {
        var newId = 0;
        if ( len( user.getId() ) ) {
            variables.users[ user.getId() ] = user;
        } else {
            // save new user
            lock type="exclusive" name="setNextID" timeout="10" throwontimeout="false" {
                newId = variables.nextId;
                ++ variables.nextId;
            }
            user.setId( newId );
            variables.users[ newId ] = user;
        }
    }

}
