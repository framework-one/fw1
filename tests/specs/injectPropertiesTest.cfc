component extends="testbox.system.BaseSpec" {
	// executes before all suites
	function beforeAll(){
		ioc = new framework.ioc( "" );
		ioc2 = new framework.ioc( "/tests/model" );
	}

	// executes after all suites
	function afterAll(){}

	// All suites go in here
	function run( testResults, testBox ){
		describe("A bean injected with properties", function(){
			it("errors on undefined properties in the bean", function(){
				var bean = new tests.model.beans.person();

				expect( function(){
					ioc.injectProperties( bean=bean, properties= { firstName="steven", thirdName="fail"} );
				}).toThrow();
			});

			it("does not error on undefined properties in the bean when ignoreMissing is specified", function(){
				var bean = new tests.model.beans.person();

				ioc.injectProperties( bean=bean, properties= { firstName="steven", thirdName="fail"}, ignoreMissing=true);
				expect( bean.getFirstName() ).toBe("steven");
			});

		});
	}
}
