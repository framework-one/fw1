/**
*
* @file  /Users/markdrew/Sites/aop1/interceptors/BasicAroundAdvice.cfc
* @author  
* @description
*
*/

component output="false" extends="coldspring.aop.MethodInterceptor"  {

	public function invokeMethod(methodInvocation){
		
		ArrayAppend(request.callstack, "around");
		return methodInvocation.proceed();
	}
}