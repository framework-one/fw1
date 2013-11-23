<cfcomponent output="true">
<cfsetting enablecfoutputonly="false" showdebugoutput="false">
<cfprocessingdirective suppresswhitespace="true">
   
  <cffunction name="run" access="remote" output="true" returntype="void" hint="Generates and prints HTML, JUnit style XML, or XML data based on a directory of tests.">
    <cfargument name="type" type="string" hint="Specifies the type to run: TestCase(testcase) or Directory Path (dir)" required="true" />
    <cfargument name="value" type="string" hint="The value for the type: com.foo.MyTestCase or C:/my/tests/" required="true" />
    <cfargument name="packagename" type="string" hint="The package name for JUnitReportTask" required="false" default="mxunit.testresults" />
    <cfargument name="outputformat" type="string" hint="Valid Values: HTML,XML, or JUNITXML" required="false" default="junitxml" />
    <cfargument name="recurse" required="false" default="true" hint="whether to recurse down the directory tree">
	<cfargument name="excludes" required="false" default="" hint="List of files to exclude if type is DIR">
    <cfargument name="componentPath" required="false" hint="performance improver: pass the cfc-notation. See DirectoryTestSuite for details." default="">

    <cfset var suite = createObject("component","mxunit.framework.TestSuite").TestSuite()/>
    <cfset var results = createObject("component","mxunit.framework.TestResult").TestResult()/>
    <cfscript>
      if(arguments.type is "testcase"){
       suite = createObject("component","mxunit.framework.TestSuite").TestSuite();
       suite.addAll(arguments.value);
       results = suite.run();
       }
      if(arguments.type is "dir"){
        //To Do: add args for recursion, includes, and excludes
        if(not isBoolean(arguments.recurse)){
        	arguments.recurse = false;
        }

        results = createObject("component","mxunit.runner.DirectoryTestSuite").run(directory=arguments.value, componentPath=arguments.componentPath, recurse=arguments.recurse, excludes=arguments.excludes);
      }
      //package name for JUnit reports
      results.setPackage(arguments.packagename);
    </cfscript>
    <!--- Read by Ant client and used to print summary to stdout --->
    <cfcookie name="mxunit_summary" value="#results.testRuns#,#results.testErrors#,#results.testFailures#,#results.totalExecutionTime#" />
    <!--- write the cookie first --->
        <cfheader statuscode="200" statustext="OK">
    <cfset printResults(arguments.outputformat,results) />
    <cfreturn />
 </cffunction>

  <cffunction name="printResults" access="private">
    <cfargument name="type">
    <cfargument name="results">
    <cfoutput>
	    <cfswitch expression="#type#">
	      <cfcase value="html">
	        #trim(arguments.results.getHTMLResults())#
	      </cfcase>
	      <cfcase value="xml">
	        #trim(arguments.results.getXMLResults())#
	      </cfcase>
	      <cfcase value="junitxml">
	        #trim(arguments.results.getJUnitXMLResults())#
	      </cfcase>
	      <cfdefaultcase>#trim(arguments.results.getJUnitXMLResults())#</cfdefaultcase>
	    </cfswitch>
    </cfoutput>
  </cffunction>

    <cffunction name="runFast" access="remote" output="true" returntype="void" hint="Generates and prints HTML, JUnit style XML, or XML data based on a directory of tests.">
    <cfargument name="type" type="string" hint="Specifies the type to run: TestCase(testcase) or Directory Path (dir)" required="true" />
    <cfargument name="value" type="string" hint="The value for the type: com.foo.MyTestCase or C:/my/tests/" required="true" />
    <cfargument name="packagename" type="string" hint="The package name for JUnitReportTask" required="false" default="mxunit.testresults" />
    <cfargument name="outputformat" type="string" hint="Valid Values: HTML,XML, or JUNITXML" required="false" default="junitxml" />
    <cfargument name="recurse" required="false" default="true" hint="whether to recurse down the directory tree">
	  <cfargument name="excludes" required="false" default="" hint="List of files to exclude if type is DIR">
    <cfargument name="componentPath" required="false" hint="performance improver: pass the cfc-notation. See DirectoryTestSuite for details." default="">

    <cfset var suite = createObject("component","mxunit.framework.TestSuite").TestSuite()/>
    <cfset var results = createObject("component","mxunit.framework.TestResult").TestResult()/>
    <cfscript>
      if(arguments.type is "testcase"){
       suite = createObject("component","mxunit.framework.TestSuite").TestSuite();
       suite.addAll(arguments.value);
       results = suite.run();
       }
      if(arguments.type is "dir"){
        //To Do: add args for recursion, includes, and excludes
        if(not isBoolean(arguments.recurse)){
        	arguments.recurse = false;
        }

        results = createObject("component","DirectoryTestSuite").run(directory=arguments.value, componentPath=arguments.componentPath, recurse=arguments.recurse, excludes=arguments.excludes);
      }
      //package name for JUnit reports
      results.setPackage(arguments.packagename);
    </cfscript>
    <!--- Read by Ant client and used to print summary to stdout --->
    <cfcookie name="mxunit_summary" value="#results.testRuns#,#results.testErrors#,#results.testFailures#,#results.totalExecutionTime#" />
    <!--- write the cookie first
    <cfset printResults(arguments.outputformat,results) /> --->
    <cfreturn />
 </cffunction>
</cfprocessingdirective>
</cfcomponent>
