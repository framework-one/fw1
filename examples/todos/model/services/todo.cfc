component  {
		
	public any function init(  ) {

		variables.todoFile = expandPath( "/examples/todos/assets/todo.json" )  ;
		variables.todos = deserializeJSON(fileRead( variables.todoFile ) );

	}

	public any function list( ) {

		var ret = structCopy(variables.todos); 	
		ret['keylist'] = structKeyArray(todos) ;
		arraySort( ret['keylist'] ,"numeric" , "desc");
		
		return todos ;
	
	}

	public any function get( string id ) {
		       		
		if ( structKeyExists( todos , arguments.id) ) {
			return todos[arguments.id];
		}
		else return 0;
		
	
	}

	public any function save( struct data  ) {
		

		param name="data.id" default=0;
		param name="data.title" default="No Title Provided"  ;		
		param name="data.status" default="New"  ;		
				
		todos[ data.id ]["title"] = data["title"] ;		
		todos[ data.id ]["status"] = data["status"] ;		
		
		FileWrite( todoFile, serializeJson(todos) );		
		
		return todos;
	
	}

	public any function delete(  required string id ) {

		structDelete(todos , id);		
		FileWrite( todoFile, serializeJson(todos) );		
		
		return todos;
	
	}
		
		

}
