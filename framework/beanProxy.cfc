component {
    variables._fw1_version  = "4.3.0";
    variables._aop1_version = variables._fw1_version;
/*
	Copyright (c) 2013-2018, Mark Drew, Sean Corfield, Daniel Budde

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

		http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
*/



	variables.afterInterceptors = [];
	variables.aroundInterceptors = [];
	variables.beforeInterceptors = [];
	variables.errorInterceptors = [];
	variables.interceptedMethods = "";
	variables.interceptID = createUUID();
	variables.preName = "___";
	variables.targetBean = "";
	variables.targetBeanPath = "";




	// -------------- //
	// PUBLIC METHODS //
	// -------------- //

	/** Constructor. */
	public any function init(required any bean, required array interceptors, required struct config)
	{
		variables.targetBean = arguments.bean;

		populateInterceptorCache(arguments.interceptors);
		morphTargetBean(arguments.config);
		morphProxy(arguments.config);
		cleanVarScope();

		return this;
	}


	/** Entry point for all publically accessible intercepted methods. */
	public any function onMissingMethod(string missingMethodName, struct missingMethodArguments = {})
	{
		// Prevent infinite loop and make sure the method is publically accessible.
		if ( !structKeyExists(variables.targetBean, arguments.missingMethodName) &&
         !structKeyExists(variables.targetBean, variables.preName & arguments.missingMethodName) &&
         !structKeyExists(variables.targetBean, "onMissingMethod") &&
         !structKeyExists(variables.targetBean, variables.preName & "onMissingMethod") )
		{
			var objectName = listLast(getMetadata(variables.targetBean).name, ".");
      var stdout = createObject("java","java.lang.System").out;
			stdout.println("Unable to locate method in (" & objectName & "). " &
					"The method (" & arguments.missingMethodName & ") could not be found. Please verify the method exists and is publically accessible.");
		}
    else
    {
    		local.result = runStacks(arguments.missingMethodName, arguments.missingMethodArguments);

    		if (structKeyExists(local, "result") && !isNull(local.result)) return local.result;
    }
	}


	/** Runs all the interceptor stacks. */
	public any function runStacks(string methodName, struct args = {})
	{
		var objectName = "";


		// Prevent infinite loop and make sure the method exists (public or private)
		if (!variables.targetBean.$methodExists(arguments.methodName) && !variables.targetBean.$methodExists(variables.preName & arguments.methodName))
		{
			objectName = listLast(getMetadata(this).name, ".");
			throw(message="Unable to locate method in (" & objectName & ").", detail="The method (" & arguments.methodName & ") could not be found.");
		}


		try
		{
			// Intercepted method call
			if (variables.interceptedMethods == "*" || listFindNoCase(variables.interceptedMethods, arguments.methodName))
			{
				runBeforeStack(arguments.methodName, arguments.args);
				local.result = runAroundStack(arguments.methodName, arguments.args);
				local.result = runAfterStack(arguments.methodName, arguments.args, !structKeyExists(local, "result") || isNull(local.result) ? javacast("null", 0) : local.result);
			}

			// Non-intercepted method call
			else
			{
				local.result = variables.targetBean.$call(arguments.methodName, arguments.args);
			}
		}
		catch (any exception)
		{
			if (arrayLen(variables.errorInterceptors))
			{
				runOnErrorStack(arguments.methodName, arguments.args, exception);
			}
			else
			{
				rethrow;
			}
		}


		if (structKeyExists(local, "result") && !isNull(local.result)) return local.result;
	}




	// --------------- //
	// PRIVATE METHODS //
	// --------------- //

	// --- Interceptor Augmentation Methods --- //

	/** Used to setup intercepted method lists on a per bean basis. */
	public any function _addInterceptedMethods(required string interceptID, required string methods)
	{
		var interceptedMethods = "";
		var methodName = "";


		if (!structKeyExists(variables, "interceptedMethods"))
		{
			variables.interceptedMethods = {};
		}

		if (!structKeyExists(variables.interceptedMethods, arguments.interceptID))
		{
			variables.interceptedMethods[arguments.interceptID] = "";
		}

		interceptedMethods = variables.interceptedMethods[arguments.interceptID];


		if (interceptedMethods != "*")
		{
			if (arguments.methods == "" || arguments.methods == "*")
			{
				variables.interceptedMethods[arguments.interceptID] = "*";
			}
			else
			{
				for (methodName in listToArray(arguments.methods))
				{
					if (!listFindNoCase(variables.interceptedMethods[arguments.interceptID], methodName))
					{
						interceptedMethods = listAppend(interceptedMethods, methodName);
					}
				}


				interceptedMethods = listSort(interceptedMethods, "textnocase");
				variables.interceptedMethods[arguments.interceptID] = interceptedMethods;
			}
		}
	}


	/** Used to setup intercepted method lists on a per bean basis. */
	public any function _getInterceptedMethods(string interceptID)
	{
		var methods = {};

		if (structKeyExists(variables, "interceptedMethods"))
		{
			methods = variables.interceptedMethods;
		}

		if (!structKeyExists(arguments, "interceptID"))
		{
			return methods;
		}


		if (structKeyExists(methods, arguments.interceptID))
		{
			return methods[arguments.interceptID];
		}

		return "";
	}


	/** Used to inject methods and data. */
	public any function _inject(required string key, required any value, required string access="public")
	{
		if (arguments.access == "public")
		{
			this[arguments.key] = arguments.value;
		}

		variables[arguments.key] = arguments.value;
	}


	/** Determines if an around interceptor is the last in the call chain. */
	public boolean function _isLast()
	{
		return isSimpleValue(variables.nextInterceptor);
	}


	/** Runs the 'Around' method, skips to the next interceptor in the chain if the 'Around' should not be run, or calls the actual method. */
	public any function _preAround(required any targetBean, required string methodName, struct args = {})
	{
		var interceptedMethods = getInterceptedMethods(arguments.targetBean.interceptID);

		// Match if method is to be intercepted by this interceptor.
		if (interceptedMethods == "*" || listFindNoCase(interceptedMethods, arguments.methodName))
		{
			local.result = around(arguments.targetBean, arguments.methodName, arguments.args);
		}
		else
		{
			local.result = proceed(arguments.targetBean, arguments.methodName, arguments.args);
		}

		if (structKeyExists(local, "result") && !isNull(local.result)) return local.result;
	}


	/** Runs the next around interceptor or processes the method if it is the final interceptor in the call chain. */
	public any function _proceed(required any targetBean, required string methodName, struct args = {})
	{
		if (isLast())
		{
			local.result = arguments.targetBean.$call(arguments.methodName, arguments.args, true);
		}
		else
		{
			local.result = variables.nextInterceptor.preAround(arguments.targetBean, arguments.methodName, arguments.args);
		}


		if (structKeyExists(local, "result") && !isNull(local.result)) return local.result;
	}


	/** Helper method for use inside of (after, around, before) to translate position based 'args' into name based. */
	private any function _translateArgs(required any targetBean, required string methodName, required struct args, boolean replace = false)
	{
		var i = 1;
		var key = "";
		var argumentInfo = arguments.targetBean.$getArgumentInfo(arguments.methodName);
		var resultArgs = {};

		if (structIsEmpty(arguments.args) || !structKeyExists(arguments.args, "1"))
		{
			return arguments.args;
		}

		for (i = 1; i <= arrayLen(argumentInfo); i++)
		{
			resultArgs[argumentInfo[i].name] = arguments.args[i];
		}

		if (arguments.replace)
		{
			structAppend(arguments.args, resultArgs, true);

			for (key in arguments.args)
			{
				if (isNumeric(key))
				{
					structDelete(arguments.args, key);
				}
			}
		}

		return resultArgs;
	}




	// --- Target Bean and Proxy Bean Augmentation Methods --- //

	/** Runs the appropriate method on the target bean. */
	private any function $call(required string methodName, struct args = {}, boolean original = false)
	{
		if (arguments.original)
		{
			local.result = invoke( variables, variables.preName & arguments.methodName, arguments.args );
		}
		else
		{
			local.result = invoke( variables, arguments.methodName, arguments.args );
		}

		if (structKeyExists(local, "result") && !isNull(local.result)) return local.result;
	}


	/** Used to replace any 'private' methods on the target bean that are being intercepted. Creates an intercept point. */
	public any function $callPrivateMethod()
	{
		local.methodName = getFunctionCalledName();
		local.result = $callStacks(local.methodName, arguments);

		if (structKeyExists(local, "result") && !isNull(local.result)) return local.result;
	}


	/** Used to replace any 'public' methods on the target bean that are being intercepted. Creates an intercept point. */
	public any function $callPublicMethod()
	{
		local.methodName = getFunctionCalledName();
		local.result = $callStacks(local.methodName, arguments);

		if (structKeyExists(local, "result") && !isNull(local.result)) return local.result;
	}


	/** Method called by the intercept points to start the stack run if needed. */
	private any function $callStacks(string methodName, struct args = {})
	{
		local.result = variables.beanProxy.runStacks(arguments.methodName, arguments.args);

		if (structKeyExists(local, "result") && !isNull(local.result)) return local.result;
	}


	/** Gets arguments information for a method. */
	private array function $getArgumentInfo(required string methodName)
	{
		var method = "";
		var methodMetadata = "";


		if (structKeyExists(this, variables.preName & arguments.methodName))
		{
			method = this[variables.preName & arguments.methodName];
		}
		else if (structKeyExists(this, arguments.methodName))
		{
			method = this[arguments.methodName];
		}
		else if (structKeyExists(variables, variables.preName & arguments.methodName))
		{
			method = variables[variables.preName & arguments.methodName];
		}
		else if (structKeyExists(variables, arguments.methodName))
		{
			method = variables[arguments.methodName];
		}


		if (!isSimpleValue(method))
		{
			methodMetadata = getMetadata(method);

			if (structKeyExists(methodMetadata, "parameters") && arrayLen(methodMetadata.parameters))
			{
				return methodMetadata.parameters;
			}
		}


		return [];
	}


	/** Runs the appropriate method on the target bean. */
	private boolean function $methodExists(required string methodName)
	{
		return structKeyExists(this, arguments.methodName) || structKeyExists(variables, arguments.methodName);
	}


	/** A pass through method placed on the proxy bean (used primarily for 'init', 'set..', and 'initMethod' on target bean). */
	private any function $passThrough()
	{
		local.methodName = getFunctionCalledName();
		local.result = invoke( variables.targetBean, local.methodName, arguments );

		if (structKeyExists(local, "result") && !isNull(local.result)) return local.result;
	}


	/** Used to inject methods on the target bean. */
	public any function $replaceMethod(required string methodName, required any implementedMethod, required string access="public")
	{
		var method = "";

		if (arguments.access == "public")
		{
			method = this[arguments.methodName];

			if (isCustomFunction(method))
			{
				this[variables.preName & arguments.methodName] = this[arguments.methodName];
				this[arguments.methodName] = arguments.implementedMethod;
			}
		}

		method = variables[arguments.methodName];

		if (isCustomFunction(method))
		{
			variables[variables.preName & arguments.methodName] = variables[arguments.methodName];
			variables[arguments.methodName] = arguments.implementedMethod;
		}
	}




	// --- Local Private Methods --- //

	/** Adds an interceptor definition and bean to the interceptor cache for the proxied bean. */
	private void function addInterceptor(required any interceptor)
	{
		// If someone decides to have an interceptor handle multiple interceptor types, go for it.

		if (hasAfterMethod(arguments.interceptor))
		{
			arrayAppend(variables.afterInterceptors, arguments.interceptor);
		}


		if (hasAroundMethod(arguments.interceptor))
		{
			arrayAppend(variables.aroundInterceptors, arguments.interceptor);
		}


		if (hasBeforeMethod(arguments.interceptor))
		{
			arrayAppend(variables.beforeInterceptors, arguments.interceptor);
		}


		if (hasOnErrorMethod(arguments.interceptor))
		{
			arrayAppend(variables.errorInterceptors, arguments.interceptor);
		}


		if (!structKeyExists(arguments.interceptor.bean, "interceptorAugmented"))
		{
			augmentInterceptor(arguments.interceptor);
		}


		// Maintain the list of intercepted methods. '*' and blank means all.
		if (variables.interceptedMethods != "*")
		{
			if (!len(arguments.interceptor.methods) || arguments.interceptor.methods == "*")
			{
				variables.interceptedMethods = "*";
			}
			else
			{
				variables.interceptedMethods = listSort(listAppend(variables.interceptedMethods, arguments.interceptor.methods), "textnocase");
			}
		}


		// Update the interceptor itself.
		arguments.interceptor.bean.addInterceptedMethods(variables.interceptID, arguments.interceptor.methods);
	}


	/** Adds variables and methods needed by Around interceptors. */
	private void function augmentAroundInterceptor(required any interceptor)
	{
		var prevInterceptor = "";


		// Add additional methods for an around interceptor.
		arguments.interceptor.bean._inject("isLast", _isLast);
		arguments.interceptor.bean._inject("preAround", _preAround);
		arguments.interceptor.bean._inject("proceed", _proceed);
		arguments.interceptor.bean._inject("nextInterceptor", "", "private");


		// Add a link in the call chain from the previous interceptor to the one just added.
		if (1 < arrayLen(variables.aroundInterceptors))
		{
			prevInterceptor = variables.aroundInterceptors[arrayLen(variables.aroundInterceptors) - 1];

			prevInterceptor.bean._inject = _inject;

			prevInterceptor.bean._inject("nextInterceptor", arguments.interceptor.bean, "private");

			structDelete(prevInterceptor.bean, "_inject");
		}
	}


	/** Adds variables and methods needed by all interceptors. */
	private void function augmentInterceptor(required any interceptor)
	{
		var interceptorVarScope = "";


		if (!structKeyExists(arguments.interceptor, "methods") || !len(arguments.interceptor.methods))
		{
			arguments.interceptor.methods = "*";
		}

		arguments.interceptor.bean._inject = _inject;

		arguments.interceptor.bean._inject("interceptorAugmented", true);
		arguments.interceptor.bean._inject("addInterceptedMethods", _addInterceptedMethods);
		arguments.interceptor.bean._inject("getInterceptedMethods", _getInterceptedMethods);
		arguments.interceptor.bean._inject("translateArgs", _translateArgs, "private");

		if (hasAroundMethod(arguments.interceptor))
		{
			augmentAroundInterceptor(arguments.interceptor);
		}

		structDelete(arguments.interceptor.bean, "_inject");
	}


	/** Cleans up temporary methods from the variables scope. */
	private void function cleanVarScope()
	{
		var key = "";

		for (key in variables)
		{
			if (left(key, 1) == "_" || left(key, 1) == "$")
			{
				structDelete(variables, key);
			}
		}
	}


	/** Returns whether a method's access is public or private. */
	private string function getMethodAccess(any method)
	{
		var access = "public";
		var methodMetadata = getMetadata(method);

		if (structKeyExists(methodMetadata, "access") && methodMetadata.access == "private")
		{
			access = "private";
		}

		return access;
	}


	/** Retrieves property and method info about the targetBean. */
	private struct function getTargetBeanMetadata(any beanMetadata)
	{
		var beanInfo = {accessors = false, methods = {}, name = "", properties = {}};
		var i = 0;
		var method = {};
		var property = {};
		var tmpBeanInfo = {};


		if (isObject(arguments.beanMetadata))
		{
			arguments.beanMetadata = getMetadata(arguments.beanMetadata);
		}


		if (structKeyExists(arguments.beanMetadata, "accessors"))
		{
			beanInfo.accessors = arguments.beanMetadata.accessors;
		}


		if (structKeyExists(arguments.beanMetadata, "name"))
		{
			beanInfo.name = arguments.beanMetadata.name;
		}


		// Gather method information.
		if (structKeyExists(arguments.beanMetadata, "functions"))
		{
			// ACF 9 did NOT like using a for-in loop here.
			for (i = 1; i <= arrayLen(arguments.beanMetadata.functions); i++)
			{
				method = arguments.beanMetadata.functions[i];
				beanInfo.methods[method.name] = {};

				if (structKeyExists(method, "access"))
				{
					beanInfo.methods[method.name]["access"] = method.access;
				}
			}
		}


		// Gather property information.
		if (structKeyExists(arguments.beanMetadata, "properties"))
		{
			// ACF 9 did NOT like using a for-in loop here.
			for (i = 1; i <= arrayLen(arguments.beanMetadata.properties); i++)
			{
				property = arguments.beanMetadata.properties[i];
				beanInfo.properties[property.name] = {};

				if (structKeyExists(property, "access"))
				{
					beanInfo.properties[property.name]["access"] = property.access;
				}
			}
		}


		// Handle 'extends' hierarchy info.
		if (structKeyExists(arguments.beanMetadata, "extends"))
		{
			tmpBeanInfo = getTargetBeanMetadata(arguments.beanMetadata.extends);
			structAppend(beanInfo.properties, tmpBeanInfo.properties);
			structAppend(beanInfo.methods, tmpBeanInfo.methods);
		}


		return beanInfo;
	}


	/** Gathers all the method information for the targetBean. */
	private struct function getTargetBeanMethodInfo()
	{
		var beanInfo = getTargetBeanMetadata(variables.targetBean);
		var key = "";
		var methodInfo = {};


		variables.targetBeanPath = beanInfo.name;


		// Locate methods in 'this' scope of targetBean.
		for (key in variables.targetBean)
		{
			if (!structKeyExists(methodInfo, key) && isCustomFunction(variables.targetBean[key]))
			{
				methodInfo[key] = {access = "public", discoveredIn = "this", isPropertyAccessor = false};
			}
		}


		// Locate any missing 'set' and 'get' methods only present in the metadata.
		if (beanInfo.accessors)
		{
			for (key in beanInfo.methods)
			{
				if (!structKeyExists(methodInfo, key))
				{
					methodInfo[key] = {access = beanInfo.methods[key].access, discoveredIn = "metadata", isPropertyAccessor = false};
				}
			}
		}


		// Determine if any of the 'set' or 'get' methods match a property.
		if (beanInfo.accessors)
		{
			for (key in beanInfo.properties)
			{
				if (structKeyExists(methodInfo, "set" & key))
				{
					methodInfo["set" & key].isPropertyAccessor = true;
				}


				if (structKeyExists(methodInfo, "get" & key))
				{
					methodInfo["get" & key].isPropertyAccessor = true;
				}
			}
		}


		return methodInfo;
	}


	/** Determines if an interceptor has an After method. */
	private boolean function hasAfterMethod(required any interceptor)
	{
		return structKeyExists(arguments.interceptor.bean, "after");
	}


	/** Determines if an interceptor has an Around method. */
	private boolean function hasAroundMethod(required any interceptor)
	{
		return structKeyExists(arguments.interceptor.bean, "around");
	}


	/** Determines if an interceptor has a Before method. */
	private boolean function hasBeforeMethod(required any interceptor)
	{
		return structKeyExists(arguments.interceptor.bean, "before");
	}


	/** Determines if an interceptor has an onError method. */
	private boolean function hasOnErrorMethod(required any interceptor)
	{
		return structKeyExists(arguments.interceptor.bean, "onError");
	}


	/** Determines if a 'methodName' is in a list of methods. A blank list of method matches will be an automatic match. */
	private boolean function methodMatches(string methodName, string matchers)
	{
		// Match on:  1) No matches provided  2) Method name in matchers
		return !listLen(arguments.matchers) || arguments.matchers == "*" || listFindNoCase(arguments.matchers, arguments.methodName);
	}


	/** Alters the proxy bean so the factory still sees the set..(), init(), and initMethod() and so these methods get called on the target bean. */
	private void function morphProxy(required struct config)
	{
		var key = "";

		// Handle the 'set...' methods.
		for (key in variables.targetBean)
		{
			if (left(key, 3) == "set")
			{
				this[key] = $passThrough;
			}
		}


		// Checks to see if the 'initMethod' was defined in the config and handles if it exists on the target bean.
		if (structKeyExists(arguments.config, "initMethod") && len(arguments.config.initMethod) && structKeyExists(variables.targetBean, arguments.config.initMethod))
		{
			this[arguments.config.initMethod] = $passThrough;
		}


		// Passes the init() if it exists, otherwise removes it.
		if (structKeyExists(variables.targetBean, "init"))
		{
			this["init"] = $passThrough;
		}
		else
		{
			structDelete(this, "init");
		}
	}


	/** Alters the target bean by adding intercept points. */
	private void function morphTargetBean(required struct config)
	{
		var access = "";
		var beanMethodInfo = getTargetBeanMethodInfo();
		var initMethod = "";
		var key = "";
		var method = "";
		var methodInfo = "";


		if (structKeyExists(arguments.config, "initMethod"))
		{
			initMethod = arguments.config.initMethod;
		}


		variables.targetBean.$inject = _inject;
		variables.targetBean.$replaceMethod = $replaceMethod;


		// Setup internal variables and methods on the target bean.
		variables.targetBean.$inject("beanProxy", this, "private");
		variables.targetBean.$inject("preName", variables.preName, "private");
		variables.targetBean.$inject("$callStacks", $callStacks, "private");
		variables.targetBean.$inject("$call", $call);
		variables.targetBean.$inject("$methodExists", $methodExists);
		variables.targetBean.$inject("$getArgumentInfo", $getArgumentInfo);
		variables.targetBean.$inject("interceptID", variables.interceptID);


		for (key in beanMethodInfo)
		{
			methodInfo = beanMethodInfo[key];


			// Only alter methods that should be intercepted. 'init()', accessors, and 'initMethod' are ignored unless specified in the methods list.
			if	(
					(variables.interceptedMethods == "*" && key != "init" && key != initMethod && !methodInfo.isPropertyAccessor) ||
					listFindNoCase(variables.interceptedMethods, key)
				)
			{
				// Handle methods listed in a scope.
				if (listFindNoCase("this,variables", methodInfo.discoveredIn))
				{
					// Handle methods found in 'this' scope.
					if (methodInfo.access == "public")
					{
						variables.targetBean.$replaceMethod(key, $callPublicMethod);
					}

					// Handle methods in the variables scope.
					else
					{
						variables.targetBean.$replaceMethod(key, $callPublicMethod, "private");
					}
				}


				// Handle methods found only in the metadata.
				else
				{
					try
					{
						if (methodInfo.access == "public")
						{
							variables.targetBean.$replaceMethod(key, $callPublicMethod);
						}
						else
						{
							variables.targetBean.$replaceMethod(key, $callPublicMethod, "private");
						}
					}
					catch (any exception)
					{
						throw(message="Unable to locate the method (" & key & ") on target bean (" & variables.targetBeanPath & ").");
					}
				}
			}
		}


		structDelete(variables.targetBean, "$inject");
		structDelete(variables.targetBean, "$replaceMethod");
	}


	/** Adds an array of interceptor definitions to the interceptor definition cache. */
	private void function populateInterceptorCache(required array interceptors)
	{
		var interceptor = "";

		for (interceptor in arguments.interceptors)
		{
			addInterceptor(interceptor);
		}
	}


	private any function runAfterStack(string methodName, struct args, any result)
	{
		if (structKeyExists(arguments, "result") && !isNull(arguments.result))
		{
			local.result = arguments.result;
		}


		for (local.interceptor in variables.afterInterceptors)
		{
			if (methodMatches(methodName, local.interceptor.methods))
			{
				local.tempResult = local.interceptor.bean.after(variables.targetBean, arguments.methodName, args, isNull(arguments.result) ? javacast("null", 0) : arguments.result);
			}

			if (structKeyExists(local, "tempResult"))
			{
				if (!isNull(local.tempResult))
				{
					local.result = local.tempResult;
				}

				structDelete(local, "tempResult");
			}
		}


		if (structKeyExists(local, "result") && !isNull(local.result)) return local.result;
	}


	private any function runAroundStack(string methodName, struct args)
	{
		if (arrayLen(variables.aroundInterceptors))
		{
			// Only need to call the first one in the chain to start the process.
			local.result = variables.aroundInterceptors[1].bean.preAround(variables.targetBean, arguments.methodName, arguments.args);
		}
		else
		{
			local.result = variables.targetBean.$call(arguments.methodName, arguments.args, true);
		}

		if (structKeyExists(local, "result") and !isNull(local.result)) return local.result;
	}


	private void function runBeforeStack(string methodName, struct args)
	{
		var inteceptor = "";

		for (inteceptor in variables.beforeInterceptors)
		{
			if (structKeyExists(inteceptor.bean, "before"))
			{
				if (methodMatches(arguments.methodName, inteceptor.methods))
				{
					inteceptor.bean.before(variables.targetBean, arguments.methodName, arguments.args);
				}
			}
		}
	}


	private void function runOnErrorStack(string methodName, struct args, any exception)
	{
		var interceptor = "";

		for (interceptor in variables.errorInterceptors)
		{
			if (methodMatches(arguments.methodName, interceptor.methods))
			{
				interceptor.bean.onError(variables.targetBean, arguments.methodName, arguments.args, arguments.exception);
			}
		}
	}
}
