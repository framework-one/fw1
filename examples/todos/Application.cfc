component extends="framework.one" {
	
	this.name = "todoapp";

	variables.framework = {
        unhandledExtensions = "cfc,map,css,js,html",
        unhandledPaths = "/fonts",
		generateSES = 'true',
		routes = [ //Just for fun.....
		  { "$GET/todo/:id" = "/main/get/id/:id" },
		  { "$GET/todo" = "/main/list/" },
		  { "$DELETE/todo/:id" = "/main/delete/id/:id" },
		  { "$POST/todo/" = "/main/save" }
		]	
	};
	
	function setupApplication() {
		
	}

	function setupRequest() {

	}		

}
