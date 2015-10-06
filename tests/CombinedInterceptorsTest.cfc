component extends="mxunit.framework.TestCase" {

	function TestBeforeAroundAfterInterception() {
		//Putting it all together What happens when you call all of them?
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});
		//add an Interceptor

		bf.intercept("ReverseService", "BeforeInterceptor");
		bf.intercept("ReverseService", "AroundInterceptor");
		bf.intercept("ReverseService", "AfterInterceptor");

		rs = bf.getBean("ReverseService");
		result = rs.doReverse("Hello!");


		AssertEquals("around," & Reverse("beforeHello!") & ",around", result);
		AssertEquals(4, arrayLen(request.callstack));
		AssertEquals("before,around,doReverse,after", arrayToList(request.callstack));
	}


	function TestInitMethods() {
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {initMethod = "configure"});

		bf.intercept("advReverse", "BeforeInterceptor");

		rs = bf.getBean("advReverse");
		result = rs.doWrap("Hello!");

		// First test does not intercept the (init, set..., or initMethod) methods.
		AssertEquals(9, arrayLen(request.callstack));
		AssertEquals(	"init,setStackLogService,configure,before,dowrap,before,dofront,before,dorear", 
						arrayToList(request.callstack), 
						"This test shows that the (init, set..., and configure) methods are by default ignored.");


		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {initMethod = "configure"});

		bf.intercept("advReverse", "BeforeInterceptor", "init,configure,setStackLogService,doWrap");

		rs = bf.getBean("advReverse");
		result = rs.doWrap("Hello!");

		// Explicitly intercept the (init, set..., or initMethod) methods.
		AssertEquals(10, arrayLen(request.callstack));
		AssertEquals(	"before,init,before,setStackLogService,before,configure,before,dowrap,dofront,dorear", 
						arrayToList(request.callstack), 
						"This test shows that the (init, set..., and configure) methods can be explicitly intercepted.");
	}


	function TestInterceptOnRegex() {
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {initMethod = "configure"});

		//add an Interceptor
		bf.intercept("/^reverse.*$/", "BeforeInterceptor");

		ars = bf.getBean("advReverse");
		rs = bf.getBean("reverse");
		as = bf.getBean("array");


		result = ars.doWrap("Hello!");
		result2 = rs.doReverse("Hello!");
		result3 = as.doListToArray("dog,cat,mouse");


		AssertEquals("front-Hello!-rear", result);
		AssertEquals("!olleHerofeb", result2);
		AssertTrue(isArray(result3));
		AssertEquals("dog,cat,mouse", arrayToList(result3));

		AssertEquals(9, arrayLen(request.callstack));
		AssertEquals("init,setStackLogService,configure,doWrap,doFront,doRear,before,doReverse,doListToArray", arrayToList(request.callstack));
	}


	function TestInterceptOnType() {
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {initMethod = "configure"});

		//add an Interceptor
		bf.interceptByType("stringService", "BeforeInterceptor", "doReverse,doForward,doWrap");

		ars = bf.getBean("advReverse");
		rs = bf.getBean("reverse");
		as = bf.getBean("array");


		result = ars.doWrap("Hello!");
		result2 = rs.doReverse("Hello!");
		result3 = as.doListToArray("dog,cat,mouse");


		AssertEquals("front-beforeHello!-rear", result);
		AssertEquals("!olleHerofeb", result2);
		AssertTrue(isArray(result3));
		AssertEquals("dog,cat,mouse", arrayToList(result3));

		AssertEquals(10, arrayLen(request.callstack));
		AssertEquals("init,setStackLogService,configure,before,doWrap,doFront,doRear,before,doReverse,doListToArray", arrayToList(request.callstack));
	}


	function TestMultipleBeforeInterceptions() {
		//Multiple Before Advisors
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});

		//Need to create different Before interceptors
		bf.declareBean("BeforeInterceptorA", "tests.aop.interceptors.aop.BeforeInterceptor", true, {name = "beforeA"});
		bf.declareBean("BeforeInterceptorB", "tests.aop.interceptors.aop.BeforeInterceptor", true, {name = "beforeB"});
		bf.declareBean("BeforeInterceptorC", "tests.aop.interceptors.aop.BeforeInterceptor", true, {name = "beforeC"});

		bf.intercept("ReverseService", "BeforeInterceptorA");
		bf.intercept("ReverseService", "BeforeInterceptorB");
		bf.intercept("ReverseService", "BeforeInterceptorC");
		
		rs = bf.getBean("ReverseService");
		result = rs.doReverse("Hello!");

		AssertEquals(reverse("beforebeforebeforeHello!"), result);
		AssertEquals(4, arrayLen(request.callstack));
		AssertEquals("beforeA,beforeB,beforeC,doReverse", arrayToList(request.callstack));
	}


	function TestMultipleAfterInterceptors() {
		//Multiple After Advisors
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});

		//Need to create different After interceptors
		bf.declareBean("AfterInterceptorA", "tests.aop.interceptors.aop.AfterInterceptor", true, {name = "afterA"});
		bf.declareBean("AfterInterceptorB", "tests.aop.interceptors.aop.AfterInterceptor", true, {name = "afterAlterResultB"});
		bf.declareBean("AfterInterceptorC", "tests.aop.interceptors.aop.AfterInterceptor", true, {name = "afterC"});


		bf.intercept("ReverseService", "AfterInterceptorA");
		bf.intercept("ReverseService", "AfterInterceptorB");
		bf.intercept("ReverseService", "AfterInterceptorC");


		rs = bf.getBean("ReverseService");
		result = rs.doReverse("Hello!");

		AssertEquals(reverse("Hello!") & ",afterAlterResultB", result);
		AssertEquals(4, arrayLen(request.callstack));
		AssertEquals("doReverse,afterA,afterAlterResultB,afterC", arrayToList(request.callstack));
	}


	function TestMultipleAroundInterceptors() {
		//Multiple Around Advisors
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});


		//Need to create different After interceptors
		bf.declareBean("AroundInterceptorA", "tests.aop.interceptors.aop.AroundInterceptor", true, {name = "aroundA"});
		bf.declareBean("AroundInterceptorB", "tests.aop.interceptors.aop.AroundInterceptor", true, {name = "aroundB"});
		bf.declareBean("AroundInterceptorC", "tests.aop.interceptors.aop.AroundInterceptor", true, {name = "aroundC"});


		bf.intercept("ReverseService", "AroundInterceptorA");
		bf.intercept("ReverseService", "AroundInterceptorB");
		bf.intercept("ReverseService", "AroundInterceptorC");
		rs = bf.getBean("ReverseService");

		result = rs.doReverse("Hello!");

		AssertEquals("aroundA,aroundB,aroundC," & reverse("Hello!") & ",aroundC,aroundB,aroundA", result);
		AssertEquals(4, arrayLen(request.callstack));
		AssertEquals("aroundA,aroundB,aroundC,doReverse", arrayToList(request.callstack));
	}


	function TestMethodMatches() {
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


	function TestNamedMethodInterceptions() {
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

		AssertEquals(reverse("beforeHello!"), result);
		AssertEquals("hello!", result2);
		AssertEquals(reverse("beforeHello!"), result3);
		AssertEquals(5, arrayLen(request.callstack));
		AssertEquals("before,doReverse,doForward,before,doReverse", arrayToList(request.callstack));
	}


	function TestOnErrorInterceptors() {
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});
        rs =  bf.getBean("ReverseService");
		result2 = rs.doForward("Hello!");


		AssertEquals("Hello!", result2);
		AssertEquals(1, arrayLen(request.callstack));
		AssertEquals("doForward", arrayToList(request.callstack));


		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});
		//add an Interceptor
		bf.intercept("ReverseService", "ErrorInterceptor", "throwError");

		rs = bf.getBean("ReverseService");
		rs.throwError();

		AssertEquals(2, arrayLen(request.callstack));
		AssertEquals("throwError,onError", arrayToList(request.callstack));
	}


	function TestPrivateMethodInterceptors() {
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {initMethod = "configure"});

		//add an Interceptor
		bf.intercept("advReverse", "BeforeInterceptor", "doFront");

		rs = bf.getBean("advReverse");

		result = rs.doWrap("Hello!");

		AssertEquals("front-beforeHello!-rear", result);
		AssertEquals(7, arrayLen(request.callstack));
		AssertEquals("init,setStackLogService,configure,doWrap,before,doFront,doRear", arrayToList(request.callstack));
	}


	function TestSingleInterceptorOnMultipleObjects() {
		//Multiple Around Advisors
		request.callstack = []; //reset
		bf = new framework.aop('/tests/aop/services,/tests/aop/interceptors', {});


		//Need to create different After interceptors
		bf.declareBean("AroundInterceptorA", "tests.aop.interceptors.aop.AroundInterceptor", true, {name = "aroundA"});


		bf.intercept("advReverse", "AroundInterceptorA", "doWrap");
		bf.intercept("ReverseService", "AroundInterceptorA", "doReverse");

		rs = bf.getBean("ReverseService");
		ars = bf.getBean("advReverse");

		result = ars.doWrap(rs.doReverse("Hello!"));

		AssertEquals("aroundA,front-aroundA," & reverse("Hello!") & ",aroundA-rear,aroundA", result);
		AssertEquals(8, arrayLen(request.callstack));
		AssertEquals("init,setStackLogService,aroundA,doReverse,aroundA,doWrap,doFront,doRear", arrayToList(request.callstack));
	}
}
