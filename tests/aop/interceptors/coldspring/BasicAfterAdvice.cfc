/**
*
* @file  /Users/markdrew/Sites/aop1/interceptors/BasicAfterAdvice.cfc
* @author  
* @description
*
*/

component output="false" extends="coldspring.aop.AfterReturningAdvice" {

	

	function AfterReturning(returnVal, method, args, target){
		ArrayAppend(request.callstack, "after");
		request.AfterReturningCalled = true;
	}
}