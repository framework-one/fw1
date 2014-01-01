<cfscript>
testSuite = createObject("component","mxunit.framework.TestSuite").TestSuite();
testSuite.addAll("tests.frameworkPopulateTest");
testSuite.addAll("tests.frameworkErrorTest");
testSuite.addAll("tests.frameworkRenderTest");
testSuite.addAll("tests.frameworkRouteTest");
testSuite.addAll("tests.frameworkResourceRoutesTest");
testSuite.addAll("tests.frameworkProcessRoutesTest");
testSuite.addAll("tests.frameworkEnvTest");
testSuite.addAll("tests.onMissingViewLayoutTest");
testSuite.addAll("tests.onSessionStartBuildURLTest");
results = testSuite.run();
writeOutput(results.getResultsOutput('html'));
</cfscript>
