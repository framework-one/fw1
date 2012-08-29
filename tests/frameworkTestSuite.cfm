<cfscript>
testSuite = createObject("component","mxunit.framework.TestSuite").TestSuite();
testSuite.addAll("frameworkPopulateTest");
results = testSuite.run();
writeOutput(results.getResultsOutput('html'));
</cfscript>