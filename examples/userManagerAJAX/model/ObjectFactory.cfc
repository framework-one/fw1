<!---
	Created by: Javier Julio
	
	Original factory implementation taken from Joe Rinehart's BeanFactory 
	in the Model Glue framework with permission. Thanks Joe!
--->
<cfcomponent displayname="ObjectFactory" hint="Handles dependency injection on transient and singleton objects" output="false">

	<!--- private object properties --->
	<cfset variables.cache = structNew()>
	<cfset variables.dom = structNew()>

	<cffunction name="init" access="public" output="false" returntype="ObjectFactory">
		<cfargument name="xmlPath" type="string" required="yes">

		<cfset determinePath(arguments.xmlPath)>
		<cfset loadSingletons()>

		<cfreturn this>
	</cffunction>

	<cffunction name="getCache" access="public" output="false" returntype="struct">
		<cfreturn variables.cache>
	</cffunction>
	
	<cffunction name="getDOM" access="public" output="false" returntype="struct">
		<cfreturn variables.dom>
	</cffunction>
	
	<cffunction name="isCached" access="public" output="false" returntype="boolean">
		<cfargument name="objectName" type="string" required="yes">
		<cfreturn structKeyExists(getCache(), arguments.objectName)>
	</cffunction>

	<cffunction name="loadSingletons" access="private" output="false" returntype="void">
		<!--- define local function variables --->
		<cfset var cache = getCache()>
		<cfset var dom = getDOM()>
		<cfset var bean = "">

		<!--- loop through DOM to find all singletons --->
		<cfloop collection="#dom#" item="bean">
			<!--- add initialized singletons to cache --->
			<cfif structKeyExists(dom[bean].xmlAttributes, "singleton") AND dom[bean].xmlAttributes.singleton>
				<cfset cache[bean] = getObject(bean)>
			</cfif>
		</cfloop>
	</cffunction>
	
	<cffunction name="containsBean" access="public" output="false" returntype="boolean">
		<cfargument name="id" type="string" required="true">
		<cfreturn structKeyExists(getDom(), arguments.id)>
	</cffunction>
	
	<cffunction name="getBean" access="public" output="false" returntype="any">
		<cfargument name="id" type="string" required="true">
		<cfreturn getObject(arguments.id)>
	</cffunction>
	
	<cffunction name="getObject" access="public" output="false" returntype="any">
		<cfargument name="id" type="string" required="true">
		<cfargument name="beanRef" type="xml" required="false">

		<!--- define local function variables --->
		<cfset var properties = structNew()>
		<cfset var cache = getCache()>
		<cfset var dom = getDOM()>
		<cfset var object = "">
		<cfset var xml = "">
		<cfset var i = 0>

		<!--- if requested bean does not exist in DOM, throw an error --->
		<cfif NOT structKeyExists(dom, arguments.id)>
			<cfthrow message="Requested object is not defined" detail="The object '#arguments.id#' is not defined in factory XML via a bean tag">
		</cfif>

		<!--- if requested bean is cached, then it is a singleton --->
		<cfif isCached(arguments.id)>
			<cfset object = cache[arguments.id]>
		<cfelse>
			<!--- find all constructor arguments for the requested bean --->
			<cfif structKeyExists(arguments, "beanRef")>
				<cfset xml = xmlSearch(arguments.beanRef, "argument")>
			<cfelse>
				<cfset xml = xmlSearch(dom[arguments.id], "//bean[@id='#arguments.id#']/argument")>
			</cfif>

			<!--- store created properties in temp struct to pass to the requested object init method --->
			<cfloop index="i" from="1" to="#arrayLen(xml)#">
				<cfset properties[xml[i].xmlAttributes.name] = createProperty(xml[i])>
			</cfloop>

			<!--- if a factory bean is provided use that to create requested bean via factory method --->
			<cfif structKeyExists(dom[arguments.id].xmlAttributes, "factory") AND structKeyExists(dom[arguments.id].xmlAttributes, "method")>
				<!--- make sure the requested factory bean is configured with a bean tag --->
				<cfif NOT structKeyExists(dom, dom[arguments.id].xmlAttributes.factory)>
					<cfthrow message="Bean Factory is not defined" detail="The bean factory named '#dom[arguments.id].xmlAttributes.factory#' is not defined in factory XML via a bean tag">
				</cfif>

				<!--- save the object instance so we can call requested method later on --->
				<cfset object = getObject(dom[arguments.id].xmlAttributes.factory)>

				<!--- make sure the requested factory bean has the requested method to call --->
				<cfif NOT structKeyExists(object, dom[arguments.id].xmlAttributes.method)>
					<cfthrow message="Request method is not defined in Bean Factory" detail="The bean factory named '#dom[arguments.id].xmlAttributes.factory#' does not have a method called '#dom[arguments.id].xmlAttributes.method#' in its instance">
				</cfif>

				<!--- if we get this far then requested factory method exists, call it, and pass any constuctor arguments --->
				<cfinvoke component="#object#" method="#dom[arguments.id].xmlAttributes.method#" argumentcollection="#properties#" returnvariable="object">
			<cfelse>
				<!--- create an instance of the requested object and pass the constructor arguments --->
				<cfset object = createObject("component", dom[arguments.id].xmlAttributes.class).init(argumentCollection=properties)>
			</cfif>

			<!--- find all properties for the requested bean to set via setters --->
			<cfif structKeyExists(arguments, "beanRef")>
				<cfset xml = xmlSearch(arguments.beanRef, "property")>
			<cfelse>
				<cfset xml = xmlSearch(dom[arguments.id], "//bean[@id='#arguments.id#']/property")>
			</cfif>

			<!--- loop through all results and set each created property via bean setters --->
			<cfloop index="i" from="1" to="#arrayLen(xml)#">
				<cfinvoke component="#object#" method="set#xml[i].xmlAttributes.name#">
					<cfinvokeargument name="#xml[i].xmlAttributes.name#" value="#createProperty(xml[i])#">
				</cfinvoke>
			</cfloop>
		</cfif>

		<cfreturn object>
	</cffunction>

	<cffunction name="createProperty" access="private" output="false" returntype="any">
		<cfargument name="xml" type="any" required="yes" hint="XML of the property to create">

		<!--- define local function variables --->
		<cfset var result = "">
		<cfset var i = "">

		<cfswitch expression="#arguments.xml.xmlName#">
			<cfcase value="argument,property,element" delimiters=",">
				<!--- if the property has a value attribute then its a simple value so use that --->
				<cfif structKeyExists(arguments.xml.xmlAttributes, "value")>
					<cfset result = arguments.xml.xmlAttributes.value>
				<!--- if it contains children then it has tags such as <array>, <struct>, <ref> or <value> --->
				<cfelseif arrayLen(arguments.xml.xmlChildren)>
					<cfset result = createProperty(arguments.xml.xmlChildren[1])>
				<cfelse>
					<cfthrow message="Undefined Property Value" detail="The &lt;argument&gt;, &lt;property&gt; or &lt;element&gt; tag must have a value attribute or have any of the following tags as children: &lt;array&gt;, &lt;struct&gt;, &lt;ref&gt; or &lt;value&gt;">
				</cfif>
			</cfcase>

			<cfcase value="array">
				<cfset result = arrayNew(1)>
				<cfloop index="i" from="1" to="#arrayLen(arguments.xml.xmlChildren)#">
					<cfset result[i] = createProperty(arguments.xml.xmlChildren[i])>
				</cfloop>
			</cfcase>

			<cfcase value="bean">
				<cfset result = getObject(arguments.xml.xmlAttributes.id)>
			</cfcase>

			<cfcase value="struct">
				<cfset result = structNew()>
				<cfloop index="i" from="1" to="#arrayLen(arguments.xml.xmlChildren)#">
					<cfset result[arguments.xml.xmlChildren[i].xmlAttributes.key] = createProperty(arguments.xml.xmlChildren[i])>
				</cfloop>
			</cfcase>

			<cfcase value="ref">
				<cfif isCached(arguments.xml.xmlAttributes.bean) OR NOT arrayLen(arguments.xml.xmlChildren)>
					<cfset result = getObject(arguments.xml.xmlAttributes.bean)>
				<cfelse>
					<cfset result = getObject(arguments.xml.xmlAttributes.bean, arguments.xml)>
				</cfif>
			</cfcase>

			<cfcase value="value">
				<cfset result = arguments.xml.xmlText>
			</cfcase>
		</cfswitch>

		<cfreturn result>
	</cffunction>

	<cffunction name="determinePath" access="private" output="false" returntype="void">
		<cfargument name="xmlPath" type="string" required="yes" hint="File path or directory path to XML file(s)">

		<!--- define local function variables --->
		<cfset var qFiles = "">

		<!--- if xmlPath is a valid directory then read all xml files within that directory --->
		<cfif directoryExists(arguments.xmlPath)>
			<cfdirectory name="qFiles" directory="#arguments.xmlPath#" filter="*.xml.cfm" listinfo="name">

			<cfloop query="qFiles">
				<cfset parseXML(arguments.xmlPath & qFiles.name)>
			</cfloop>
		<cfelseif fileExists(arguments.xmlPath)>
			<cfset parseXML(arguments.xmlPath)>
		<cfelse>
			<cfthrow message="Invalid Path to Object Factory XML" detail="The path you provided #arguments.xmlPath# is an invalid directory or file path. If you have multiple XML files in a directory (on the same level) to define your beans please provide the directory path.">
		</cfif>
	</cffunction>

	<cffunction name="parseXML" access="private" output="false" returntype="void">
		<cfargument name="xmlPath" type="string" required="yes" hint="File path or directory path to XML file(s)">

		<!--- define local function variables --->
		<cfset var xml = xmlSearch(xmlParse(arguments.xmlPath), "//beans/bean")>
		<cfset var dom = getDOM()>
		<cfset var i = 0>

		<!--- for each bean in the XML store it in the DOM --->
		<cfloop index="i" from="1" to="#arrayLen(xml)#">
			<cfset dom[xml[i].xmlAttributes.id] = xml[i]>
		</cfloop>
	</cffunction>

</cfcomponent>