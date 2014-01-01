component accessors=true {

    property departmentService;
	
	variables.users = { };

    function init( departmentService, beanFactory ) {

        variables.departmentService = departmentService;
        variables.beanFactory = beanFactory;
		var user = "";
		
		// since services are cached user data we'll be persisted
		// ideally, this would be saved elsewhere, e.g. database
		
		// FIRST
		user = variables.beanFactory.getBean( "userBean" );
		user.setId("1");
		user.setFirstName("Curly");
		user.setLastName("Stooge");
		user.setEmail("curly@stooges.com");
		user.setDepartmentId("1");
		user.setDepartment(variables.departmentService.get("1"));
		
		variables.users[user.getId()] = user;
		
		// SECOND
		user = variables.beanFactory.getBean( "userBean" );
		user.setId("2");
		user.setFirstName("Larry");
		user.setLastName("Stooge");
		user.setEmail("larry@stooges.com");
		user.setDepartmentId("2");
		user.setDepartment(variables.departmentService.get("2"));
		
		variables.users[user.getId()] = user;
		
		// THIRD
		user = variables.beanFactory.getBean( "userBean" );
		user.setId("3");
		user.setFirstName("Moe");
		user.setLastName("Stooge");
		user.setEmail("moe@stooges.com");
		user.setDepartmentId("3");
		user.setDepartment(variables.departmentService.get("3"));
		
		variables.users[user.getId()] = user;
		
		// BEN
		variables.nextid = 4;
	
		return this;
    }

    function delete( id ) {
        structDelete( variables.users, id );
    }

    function get( id = "" ) {
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
            // BEN
            lock type="exclusive" name="setNextID" timeout="10" throwontimeout="false" {
                newId = variables.nextId;
                variables.nextId = variables.nextId + 1;
            }
            // END BEN
            user.setId( newId );
            variables.users[ newId ] = user;
        }
    }

}
