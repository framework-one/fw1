component {

    function init( any beanFactory ) {
        variables.beanFactory = beanFactory;
        variables.departments = { };
		
		// since services are cached department data will be persisted
		// ideally, this would be saved elsewhere, e.g. database
		
		// FIRST
        var dept = variables.beanFactory.getBean("departmentBean");
		dept.setId("1");
		dept.setName("Accounting");
		
		variables.departments[dept.getId()] = dept;
		
		// SECOND
		dept = variables.beanFactory.getBean("departmentBean");
		dept.setId("2");
		dept.setName("Sales");
		
		variables.departments[dept.getId()] = dept;
		
		// THIRD
		dept = variables.beanFactory.getBean("departmentBean");
		dept.setId("3");
		dept.setName("Support");
		
		variables.departments[dept.getId()] = dept;
		
		// FOURTH
		dept = variables.beanFactory.getBean("departmentBean");
		dept.setId("4");
		dept.setName("Development");
		
		variables.departments[dept.getId()] = dept;

        return this;
    }

    function get( string id ) {
        var result = 0;
        if ( len( id ) && structKeyExists( variables.departments, id ) ) {
            result = variables.departments[ id ];
        } else {
            result = variables.beanFactory.getBean("departmentBean");
        }
        return result;
    }

    function list() {
        return variables.departments;
    }

}
