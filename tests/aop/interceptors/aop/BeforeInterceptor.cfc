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

	function before(target, method, args){
		ArrayAppend(request.callstack, this.name);

		translateArgs(target, method, args, true);

		arguments.args.input = "before" & arguments.args.input;
	}
}