<cfscript>
testSuite = createObject("component","mxunit.framework.TestSuite").TestSuite();
testSuite.addAll("frameworkPopulateTest");
testSuite.addAll("frameworkErrorTest");
results = testSuite.run();
writeOutput(results.getResultsOutput('html'));
</cfscript>