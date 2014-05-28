component extends="mxunit.framework.TestCase"{


	function TestNoInterceptors(){
		request.callstack = [];
		bf = new framework.aop('/tests/aop/services', {});
		rs = bf.getBean("ReverseService");
		
		//Basic Bean Tests
		result = rs.doReverse("Hello!");
		AssertEquals("!olleH", result);
		AssertEquals(ArrayLen(request.callstack),1);
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
		AssertEquals(result, Reverse("beforeHello!"), "Before Works");
		AssertEquals(ArrayLen(request.callstack),2);
		AssertEquals(ArrayToList(request.callstack),"before,doReverse");
	}
	
	function TestAfterInterceptors(){
		//AfterAdvice Tests
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});
		//add an Interceptor
		bf.intercept("ReverseService", "AfterInterceptor");
		rs = bf.getBean("ReverseService");
		result = rs.doReverse("Hello!");

		AssertEquals(result, Reverse("Hello!") , "Reverse still Works");	
		AssertEquals(ArrayLen(request.callstack),2);
		AssertEquals(ArrayToList(request.callstack),"doReverse,after");
	}



	function TestAroundInterceptors(){
		//AroundAdvice Tests
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});
		//add an Interceptor
		bf.intercept("ReverseService", "AroundInterceptor");
		rs = bf.getBean("ReverseService");
		result = rs.doReverse("Hello!");


		AssertEquals(result, Reverse("Hello!") , "Called method through Around");
		AssertEquals(ArrayLen(request.callstack),2);
		AssertEquals(ArrayToList(request.callstack),"around,doReverse");
	}

	
}
