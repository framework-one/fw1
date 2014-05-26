component accessors=true {
	
	variables.departments = { };
	
	function init( beanFactory ) {
        variables.beanFactory = beanFactory;
		var dept = "";
		
		// since services are cached department data we'll be persisted
		// ideally, this would be saved elsewhere, e.g. database
		
		// FIRST
		dept = beanFactory.getBean("departmentBean");
		dept.setId("1");
		dept.setName("Accounting");
		
		variables.departments[dept.getId()] = dept;
		
		// SECOND
		dept = beanFactory.getBean("departmentBean");
		dept.setId("2");
		dept.setName("Sales");
		
		variables.departments[dept.getId()] = dept;
		
		// THIRD
		dept = beanFactory.getBean("departmentBean");
		dept.setId("3");
		dept.setName("Support");
		
		variables.departments[dept.getId()] = dept;
		
		// FOURTH
		dept = beanFactory.getBean("departmentBean");
		dept.setId("4");
		dept.setName("Development");
		
		variables.departments[dept.getId()] = dept;
		return this;
	}
	
	function get(id) {
		var result = "";
		
		if ( len(id) && structKeyExists(variables.departments, id) ) {
			result = variables.departments[id];
		} else {
			result = variables.beanFactory.getBean("departmentBean");
		}
		
		return result;
	}
	
	function list() {
		return variables.departments;
    }
	
}
