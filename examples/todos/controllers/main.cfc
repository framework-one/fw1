component accessors = true { 

	property framework;
	property todoservice;

	public void function default( struct rc ) {
		
		location(url:"index.html",addtoken:false);
	
	}

	public void function get( struct rc ) {
		
		var todobean = todoservice.get(arguments.rc.id);
		
		framework.renderdata("JSON" , todobean);
	
	}

	public void function delete( struct rc ) {
		
		var ret = todoservice.delete(arguments.rc.id);
		
		framework.renderdata("JSON" , ret);
	
	}

	public void function list( struct rc ) {
		
		var todos = todoservice.list();

		framework.renderdata("JSON" , todos);
	
	}

	public void function save( struct rc ) {
							
		var ret = todoservice.save( arguments.rc );

		framework.renderdata("JSON" , ret);
	
	}

}