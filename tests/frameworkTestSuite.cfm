<cfscript>
testSuite = createObject("component","mxunit.framework.TestSuite").TestSuite();
testSuite.addAll("tests.frameworkPopulateTest");
testSuite.addAll("tests.frameworkErrorTest");
testSuite.addAll("tests.frameworkRouteTest");
testSuite.addAll("tests.frameworkEnvTest");
testSuite.addAll("tests.onMissingViewLayout");
testSuite.addAll("tests.onSessionStartBuildURL");
results = testSuite.run();
writeOutput(results.getResultsOutput('html'));
</cfscript>
