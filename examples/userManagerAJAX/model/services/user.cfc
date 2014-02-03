<cfcomponent displayname="UserService" output="false">
	
	<cfset variables.users = structNew()>
	
	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="departmentService" type="any" required="true" />
		
		<cfscript>
		var user = "";
		var deptService = arguments.departmentService;
		
		setDepartmentService(arguments.departmentService);
		
		// since services are cached user data we'll be persisted
		// ideally, this would be saved elsewhere, e.g. database
		
		// FIRST
		user = new();
		user.setId("1");
		user.setFirstName("Curly");
		user.setLastName("Stooge");
		user.setEmail("curly@stooges.com");
		user.setDepartmentId("1");
		user.setDepartment(deptService.get("1"));
		
		variables.users[user.getId()] = user;
		
		// SECOND
		user = new();
		user.setId("2");
		user.setFirstName("Larry");
		user.setLastName("Stooge");
		user.setEmail("larry@stooges.com");
		user.setDepartmentId("2");
		user.setDepartment(deptService.get("2"));
		
		variables.users[user.getId()] = user;
		
		// THIRD
		user = new();
		user.setId("3");
		user.setFirstName("Moe");
		user.setLastName("Stooge");
		user.setEmail("moe@stooges.com");
		user.setDepartmentId("3");
		user.setDepartment(deptService.get("3"));
		
		variables.users[user.getId()] = user;
		
		// BEN
		variables.nextid = 4;
	
		</cfscript>
		
		<cfreturn this>
	</cffunction>
	
	<cffunction name="setDepartmentService" access="public" output="false">
		<cfargument name="departmentService" type="any" required="true" />
		<cfset variables.departmentService = arguments.departmentService />
	</cffunction>
	<cffunction name="getDepartmentService" access="public" returntype="any" output="false">
		<cfreturn variables.departmentService />
	</cffunction>
	
	<cffunction name="delete" access="public" output="false" returntype="boolean">
		<cfargument name="id" type="string" required="true">
		
		<cfreturn structDelete(variables.users, arguments.id)>
	</cffunction>
	
	<cffunction name="get" access="public" output="false" returntype="any">
		<cfargument name="id" type="string" required="false" default="">
		
		<cfset var result = "">
		
		<cfif len(id) AND structKeyExists(variables.users, id)>
			<cfset result = variables.users[id]>
		<cfelse>
			<cfset result = new()>
		</cfif>
		
		<cfreturn result>
	</cffunction>
	
	<cffunction name="list" access="public" output="false" returntype="struct">
		<cfreturn variables.users>
    </cffunction>
	
	<cffunction name="new" access="public" output="false" returntype="any">
		<cfreturn createObject("component", "userManagerAJAX.model.User").init()>
	</cffunction>
	
	<cffunction name="save" access="public" output="false" returntype="void">
		<cfargument name="user" type="any" required="true">
		
		<cfset var newId = 0>
		
		<!--- since we have an id we are updating a user --->
		<cfif len(arguments.user.getId())>
			<cfset variables.users[arguments.user.getId()] = arguments.user>
		<cfelse>
			<!--- otherwise a new user is being saved --->
			<!--- BEN --->
			<cflock type="exclusive" name="setNextID" timeout="10" throwontimeout="false">
				<cfset newId = variables.nextid>
				<cfset variables.nextid = variables.nextid + 1>
			</cflock>
			<!--- END BEN --->
			
			<cfset arguments.user.setId(newId)>
			
			<cfset variables.users[newId] = arguments.user>
		</cfif>
	</cffunction>
	
</cfcomponent>