/**
*
* @file  /Users/markdrew/Sites/aop1/interceptors/BeforeInterceptor.cfc
* @author  
* @description
*
*/

component output="false" displayname="BeforeInterceptor"  {
	
	this.name = "before";
	function init(name="before"){
		this.name=name;
	}

	function before(method,args,target){
		ArrayAppend(request.callstack, this.name);
		arguments.args.input = "before" & arguments.args.input;
	}
}