component accessors=true {

    property departmentService;
    property beanFactory;

    variables.users = { };
    variables.nextId = 0;

    function init( deoartmentService ) {

		var user = "";
		var deptService = arguments.departmentService;
		
		setDepartmentService(arguments.departmentService);
		
		// since services are cached user data we'll be persisted
		// ideally, this would be saved elsewhere, e.g. database
		
		// FIRST
		user = variables.beanFactory.getBean( "user" );
		user.setId("1");
		user.setFirstName("Curly");
		user.setLastName("Stooge");
		user.setEmail("curly@stooges.com");
		user.setDepartmentId("1");
		user.setDepartment(deptService.get("1"));
		
		variables.users[user.getId()] = user;
		
		// SECOND
		user = variables.beanFactory.getBean( "user" );
		user.setId("2");
		user.setFirstName("Larry");
		user.setLastName("Stooge");
		user.setEmail("larry@stooges.com");
		user.setDepartmentId("2");
		user.setDepartment(deptService.get("2"));
		
		variables.users[user.getId()] = user;
		
		// THIRD
		user = variables.beanFactory.getBean( "user" );
		user.setId("3");
		user.setFirstName("Moe");
		user.setLastName("Stooge");
		user.setEmail("moe@stooges.com");
		user.setDepartmentId("3");
		user.setDepartment(deptService.get("3"));
		
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
            result = variables.beanFactory.getBean( "user" );
        }
        return result;
    }

    function list() {
        return variables.users;
    }

    function save( user ) {
        var newId = 0;
        if ( len( user.getId() ) {
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
