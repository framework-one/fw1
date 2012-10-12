<cfscript>
testSuite = createObject("component","mxunit.framework.TestSuite").TestSuite();
testSuite.addAll("frameworkPopulateTest");
testSuite.addAll("frameworkErrorTest");
testSuite.addAll("frameworkRouteTest");
results = testSuite.run();
writeOutput(results.getResultsOutput('html'));
</cfscript>