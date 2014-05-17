<cfcomponent displayname="DepartmentService" output="false">
	
	<cfset variables.departments = structNew()>
	
	<cffunction name="init" access="public" output="false" returntype="any">
		<cfscript>
		var dept = "";
		
		// since services are cached department data we'll be persisted
		// ideally, this would be saved elsewhere, e.g. database
		
		// FIRST
		dept = new();
		dept.setId("1");
		dept.setName("Accounting");
		
		variables.departments[dept.getId()] = dept;
		
		// SECOND
		dept = new();
		dept.setId("2");
		dept.setName("Sales");
		
		variables.departments[dept.getId()] = dept;
		
		// THIRD
		dept = new();
		dept.setId("3");
		dept.setName("Support");
		
		variables.departments[dept.getId()] = dept;
		
		// FOURTH
		dept = new();
		dept.setId("4");
		dept.setName("Development");
		
		variables.departments[dept.getId()] = dept;
		</cfscript>
		
		<cfreturn this>
	</cffunction>
	
	<cffunction name="get" access="public" output="false" returntype="any">
		<cfargument name="id" type="string" required="true">
		
		<cfset var result = "">
		
		<cfif len(id) AND structKeyExists(variables.departments, id)>
			<cfset result = variables.departments[id]>
		<cfelse>
			<cfset result = new()>
		</cfif>
		
		<cfreturn result>
	</cffunction>
	
	<cffunction name="list" access="public" output="false" returntype="struct">
		<cfreturn variables.departments>
    </cffunction>
	
	<cffunction name="new" access="public" output="false" returntype="any">
		<cfreturn createObject("component", "userManager.model.Department").init()>
	</cffunction>
	
</cfcomponent>