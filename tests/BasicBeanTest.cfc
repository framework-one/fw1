component extends="mxunit.framework.TestCase" {


	function TestNoInterceptors(){
		request.callstack = [];
		bf = new framework.aop('/tests/aop/services', {});
		rs = bf.getBean("ReverseService");
		
		//Basic Bean Tests
		result = rs.doReverse("Hello!");
		AssertEquals("!olleH", result);
		AssertEquals(ArrayLen(request.callstack), 1);
		AssertEquals(ArrayToList(request.callstack),"doReverse");
	}


	function TestBeforeInterceptors(){

		//BeforeAdvice Tests
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});
		//add an Interceptor
		bf.intercept("ReverseService", "BeforeInterceptor");
		rs = bf.getBean("ReverseService");
		
		result = rs.doReverse("Hello!");

		AssertEquals(reverse("beforeHello!"), result, "Before Works");
		AssertEquals(2, arrayLen(request.callstack));
		AssertEquals("before,doReverse", arrayToList(request.callstack));
	}
	

	function TestAfterInterceptors(){
		//AfterAdvice Tests
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});

		//add an Interceptor
		bf.intercept("ReverseService", "AfterInterceptor");

		rs = bf.getBean("ReverseService");

		result = rs.doReverse("Hello!");

		AssertEquals(reverse("Hello!"), result, "Reverse still Works");	
		AssertEquals(2, ArrayLen(request.callstack));
		AssertEquals("doReverse,after", ArrayToList(request.callstack));
	}


	function TestAroundInterceptors(){
		//AroundAdvice Tests
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});
		//add an Interceptor
		bf.intercept("ReverseService", "AroundInterceptor");
		rs = bf.getBean("ReverseService");

		result = rs.doReverse("Hello!");

		AssertEquals("around," & reverse("Hello!") & ",around", result, "Called method through Around");
		AssertEquals(arrayLen(request.callstack), 2);
		AssertEquals("around,doReverse", arrayToList(request.callstack));
	}
}