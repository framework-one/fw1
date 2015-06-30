component extends="mxunit.framework.TestCase"{


	function TestBeforeAroundAfterInterception(){

		//Putting it all together What happens when you call all of them?
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});
		//add an Interceptor

		bf.intercept("ReverseService", "BeforeInterceptor");
		bf.intercept("ReverseService", "AroundInterceptor");
		bf.intercept("ReverseService", "AfterInterceptor");

		rs = bf.getBean("ReverseService");
		result = rs.doReverse("Hello!");


		AssertEquals(result, "around," & Reverse("beforeHello!") & ",around");
		AssertEquals(ArrayLen(request.callstack), 4);
		AssertEquals(ArrayToList(request.callstack),"before,around,doReverse,after");
	}

	function TestInitMethods(){
	
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {initMethod = "configure"});
		rs = bf.getBean("advReverse");

		AssertEquals(ArrayLen(request.callstack), 2);
		AssertEquals(ArrayToList(request.callstack),"init,configure");
	}

	function TestMultipleBeforeInterceptions(){
		//Multiple Before Advisors
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});
		//Need to create different Before interceptors

		bf.addBean("BeforeInterceptorA", new tests.aop.interceptors.aop.BeforeInterceptor("beforeA"));
		bf.addBean("BeforeInterceptorB", new tests.aop.interceptors.aop.BeforeInterceptor("beforeB"));
		bf.addBean("BeforeInterceptorC", new tests.aop.interceptors.aop.BeforeInterceptor("beforeC"));
		bf.intercept("ReverseService", "BeforeInterceptorA");
		bf.intercept("ReverseService", "BeforeInterceptorB");
		bf.intercept("ReverseService", "BeforeInterceptorC");
		
		rs = bf.getBean("ReverseService");
		result = rs.doReverse("Hello!");

		AssertEquals(result, Reverse("beforebeforebeforeHello!"));
		AssertEquals(ArrayLen(request.callstack),4);
		AssertEquals(ArrayToList(request.callstack),"beforeA,beforeB,beforeC,doReverse");
		
	}

	function TestMultipleAfterInterceptors(){
		//Multiple After Advisors
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});
		//Need to create different Before interceptors

		bf.addBean("AfterInterceptorA", new tests.aop.interceptors.aop.AfterInterceptor("afterA"));
		bf.addBean("AfterInterceptorB", new tests.aop.interceptors.aop.AfterInterceptor("afterAlterResultB"));
		bf.addBean("AfterInterceptorC", new tests.aop.interceptors.aop.AfterInterceptor("afterC"));
		bf.intercept("ReverseService", "AfterInterceptorA");
		bf.intercept("ReverseService", "AfterInterceptorB");
		bf.intercept("ReverseService", "AfterInterceptorC");
		rs = bf.getBean("ReverseService");
		result = rs.doReverse("Hello!");

		AssertEquals(result, Reverse("Hello!") & ",afterAlterResultB");
		AssertEquals(ArrayLen(request.callstack),4);
		AssertEquals(ArrayToList(request.callstack),"doReverse,afterA,afterAlterResultB,afterC");
	}

	function TestMultipleAroundInterceptors(){

		//Multiple Around Advisors
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});
		//Need to create different Before interceptors

		bf.addBean("AroundInterceptorA", new tests.aop.interceptors.aop.AroundInterceptor("aroundA"));
		bf.addBean("AroundInterceptorB", new tests.aop.interceptors.aop.AroundInterceptor("aroundB"));
		bf.addBean("AroundInterceptorC", new tests.aop.interceptors.aop.AroundInterceptor("aroundC"));
		bf.intercept("ReverseService", "AroundInterceptorA");
		bf.intercept("ReverseService", "AroundInterceptorB");
		bf.intercept("ReverseService", "AroundInterceptorC");
		rs = bf.getBean("ReverseService");

		result = rs.doReverse("Hello!");

		AssertEquals(result, "aroundA,aroundB,aroundC," & Reverse("Hello!") & ",aroundC,aroundB,aroundA");
		AssertEquals(ArrayLen(request.callstack),4);
		AssertEquals(ArrayToList(request.callstack),"aroundA,aroundB,aroundC,doReverse");

	}

	function TestMethodMatches(){
		bf = new framework.ioc('/tests/aop/services,/tests/aop/interceptors', {});
		rs = bf.getBean("Reverse");

		proxy = new framework.beanProxy(rs, [], {});
        makePublic( proxy, "methodMatches" );

		AssertFalse(proxy.methodMatches("doForward", "doReverse"));
		AssertTrue(proxy.methodMatches("doForward", ""));
		AssertTrue(proxy.methodMatches("doForward", "*"));
		AssertFalse(proxy.methodMatches("doForward", "doReverse,"));
		AssertTrue(proxy.methodMatches("doForward", "doReverse,doForward"));
	}

	function TestNamedMethodInterceptions(){

		//Named Method Interceptions

		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});
		//add an Interceptor
		bf.intercept("ReverseService", "BeforeInterceptor", "doReverse");

		rs = bf.getBean("ReverseService");

		// This should be intercepted.
		result = rs.doReverse("Hello!");

		// This shoud not be intercepted.
		result2 = rs.doForward("Hello!");


		// This should be intercepted.
		result3 = rs.doReverse("Hello!");

		AssertEquals(result, Reverse("beforeHello!"));
		AssertEquals(result2, "hello!");
		AssertEquals(result3, Reverse("beforeHello!"));
		AssertEquals(ArrayLen(request.callstack),5);
		AssertEquals(ArrayToList(request.callstack),"before,doReverse,doForward,before,doReverse");

	}

	function TestOnErrorInterceptors() {
	
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});
        rs =  bf.getBean("ReverseService");
		result2 = rs.doForward("Hello!");


		AssertEquals(result2, "Hello!");
		AssertEquals(ArrayLen(request.callstack),1);
		AssertEquals(ArrayToList(request.callstack),"doForward");

		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});
		//add an Interceptor
		bf.intercept("ReverseService", "ErrorInterceptor", "throwError");

		rs = bf.getBean("ReverseService");
		rs.throwError();

		AssertEquals(ArrayLen(request.callstack),2);
		AssertEquals(ArrayToList(request.callstack),"throwError,onError");
	}


	function TestPrivateMethodInterceptors(){
	
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {initMethod = "configure"});

		//add an Interceptor
		bf.intercept("advReverse", "BeforeInterceptor", "doFront");

		rs = bf.getBean("advReverse");

		result = rs.doWrap("Hello!");

		AssertEquals(result, "front-beforeHello!-rear");
		AssertEquals(ArrayLen(request.callstack), 6);
		AssertEquals(ArrayToList(request.callstack),"init,configure,doWrap,before,doFront,doRear");
	}
}
