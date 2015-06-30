component {
    variables._fw1_version = "3.5.0-snapshot";
    variables._aop1_version = "2.0.1-snapshot";
/*
	Copyright (c) 2013-2015, Mark Drew, Sean Corfield, Daniel Budde

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
	variables.preName = "";
	variables.targetBean = "";




	// -------------- //
	// PUBLIC METHODS //
	// -------------- //

	/** Adds an interceptor definition and bean to the interceptor cache for the proxied bean. */
	public void function addInterceptor(required any interceptor)
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


		augmentInterceptor(arguments.interceptor);


		// Maintain the list of intercepted methods. '*' and blank means all.
		if (variables.interceptedMethods != "*")
		{
			if (!len(interceptor.methods) || interceptor.methods == "*")
			{
				variables.interceptedMethods = "*";
			}
			else
			{
				variables.interceptedMethods = listSort(listAppend(variables.interceptedMethods, interceptor.methods), "textnocase");
			}
		}
	}


	/** Constructor. */
	public any function init(required any bean, required array interceptors, required struct config)
	{
		variables.targetBean = arguments.bean;
		variables.preName = "___";

		populateInterceptorCache(arguments.interceptors);
		morphTargetBeanInterceptedMethods();
		setupSetMethods();

		this["init"] = __passThrough;

		if (structKeyExists(arguments.config, "initMethod") && len(arguments.config.initMethod) && structKeyExists(variables.targetBean, arguments.config.initMethod))
		{
			this[arguments.config.initMethod] = __passThrough;
		}

		return this;
	}


	/** Entry point for all publically accessible intercepted methods. */
	public any function onMissingMethod(string missingMethodName, struct missingMethodArguments = {})
	{
		// Prevent infinite loop and make sure the method is publically accessible.
		if (!structKeyExists(variables.targetBean, arguments.missingMethodName) && !structKeyExists(variables.targetBean, variables.preName & arguments.missingMethodName))
		{
			objectName = listLast(getMetadata(this).name, ".");
			throw(	message="Unable to locate method in (" & objectName & ").",
					detail="The method (" & arguments.missingMethodName & ") could not be found. Please verify the method exists and is publically accessible.");
		}


		local.result = runStacks(arguments.missingMethodName, arguments.missingMethodArguments);

		if (structKeyExists(local, "result") && !isNull(local.result)) return local.result;
	}


	/** Runs all the interceptor stacks. */
	public any function runStacks(string methodName, struct args = {})
	{
		var objectName = "";


		// Prevent infinite loop and make sure the method exists (public or private)
		if (	!structKeyExists(variables.targetBean, arguments.methodName) &&
				!structKeyExists(variables.targetBean, variables.preName & arguments.methodName) &&
				!structKeyExists(variables.targetBean._v(), arguments.methodName) &&
				!structKeyExists(variables.targetBean._v(), variables.preName & arguments.methodName))
		{
			objectName = listLast(getMetadata(this).name, ".");
			throw(message="Unable to locate method in (" & objectName & ").", detail="The method (" & arguments.methodName & ") could not be found.");
		}


		try
		{
			// Intercepted method call
			if (variables.interceptedMethods == "*" || listFindNoCase(variables.interceptedMethods, arguments.methodName))
			{
				runBeforeStack(variables.targetBean, arguments.methodName, arguments.args);
				local.result = runAroundStack(variables.targetBean, arguments.methodName, arguments.args);
				local.result = runAfterStack(variables.targetBean, arguments.methodName, arguments.args, !structKeyExists(local, "result") || isNull(local.result) ? javacast("null", 0) : local.result);
			}

			// Non-intercepted method call
			else
			{
				local.result = _runMethod(variables.targetBean, arguments.methodName, arguments.args);
			}
		}
		catch (any exception)
		{
			if (arrayLen(variables.errorInterceptors))
			{
				runOnErrorStack(variables.targetBean, arguments.methodName, arguments.args, exception);
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

	/** Determines if an around interceptor is the last in the call chain. */
	public boolean function _isLast()
	{
		return isSimpleValue(variables.nextInterceptor);
	}


	/** Used to temporarily augment a bean and makes the variables scope of the bean accessible for transgenesis */
	private struct function _liftVariablesScope()
	{
		return variables;
	}


	/** Runs the 'Around' method, skips to the next interceptor in the chain if the 'Around' should not be run, or calls the actual method. */
	public any function _preAround(required any targetBean, required string methodName, struct args = {})
	{
		// Match if method is to be intercepted by this interceptor.
		if (variables.interceptedMethods == "*" || listFindNoCase(variables.interceptedMethods, arguments.methodName))
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
			local.result = runMethod(arguments.targetBean, arguments.methodName, arguments.args);
		}
		else
		{
			local.result = variables.nextInterceptor.preAround(arguments.targetBean, arguments.methodName, arguments.args);
		}


		if (structKeyExists(local, "result") && !isNull(local.result)) return local.result;
	}


	/** Runs the appropriate method on the target bean. */
	private any function _runMethod(required any targetBean, required string methodName, struct args = {})
	{
		// Public method intercept
		if (structKeyExists(arguments.targetBean, variables.preName & arguments.methodName))
		{
			local.result = evaluate("arguments.targetBean." & variables.preName & arguments.methodName & "(argumentCollection = arguments.args)");
		}

		// Private method intercept
		else if (structKeyExists(arguments.targetBean._v(), variables.preName & arguments.methodName))
		{
			local.result = evaluate("arguments.targetBean._v()." & variables.preName & arguments.methodName & "(argumentCollection = arguments.args)");
		}


		// Public method, no intercept
		else
		{
			local.result = evaluate("arguments.targetBean." & arguments.methodName & "(argumentCollection = arguments.args)");
		}


		if (structKeyExists(local, "result") && !isNull(local.result)) return local.result;
	}


	/** Helper method for use inside of (after, around, before) to translate position based 'args' into name based. */
	private any function _translateArgs(required any targetBean, required string methodName, required struct args, boolean replace = false)
	{
		var i = 1;
		var key = "";
		var metadata = {};
		var method = arguments.targetBean._v()[variables.preName & arguments.methodName];
		var resultArgs = {};

		if (structIsEmpty(arguments.args) || !structKeyExists(arguments.args, "1"))
		{
			return arguments.args;
		}

		metadata = getMetadata(method);

		for (i = 1; i <= arrayLen(metadata.parameters); i++)
		{
			resultArgs[metadata.parameters[i].name] = arguments.args[i];
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




	// --- Target Bean Augmentation Methods --- //

	/** Used to replace any 'private' methods on the target bean that are being intercepted. Creates an intercept point. */
	private any function __callPrivateMethod()
	{
		local.methodName = getFunctionCalledName();
		local.result = callStacks(local.methodName, arguments);

		if (structKeyExists(local, "result") && !isNull(local.result)) return local.result;
	}


	/** Used to replace any 'public' methods on the target bean that are being intercepted. Creates an intercept point. */
	public any function __callPublicMethod()
	{
		local.methodName = getFunctionCalledName();
		local.result = callStacks(local.methodName, arguments);

		if (structKeyExists(local, "result") && !isNull(local.result)) return local.result;
	}


	/** Method called by the intercept points to start the stack run if needed. */
	private any function __callStacks(string methodName, struct args = {})
	{
		local.result = variables.beanProxy.runStacks(arguments.methodName, arguments.args);

		if (structKeyExists(local, "result") && !isNull(local.result)) return local.result;
	}


	/** A pass through method placed on the proxy bean (used primarily for 'init' and 'init-method' on target bean). */
	private any function __passThrough()
	{
		local.methodName = getFunctionCalledName();
		local.result = _runMethod(variables.targetBean, local.methodName, arguments);

		if (structKeyExists(local, "result") && !isNull(local.result)) return local.result;
	}




	// --- Local Private Methods --- //

	/** Adds variables and methods needed by Around interceptors. */
	private void function augmentAroundInterceptor(required any interceptor)
	{
		var interceptorVarScope = "";
		var prevInterceptor = "";

		interceptorVarScope = arguments.interceptor.bean._v();


		// Add additional methods for an around interceptor.
		arguments.interceptor.bean.isLast = _isLast;
		interceptorVarScope.isLast = _isLast;

		arguments.interceptor.bean.preAround = _preAround;
		interceptorVarScope.preAround = _preAround;

		arguments.interceptor.bean.proceed = _proceed;
		interceptorVarScope.proceed = _proceed;

		interceptorVarScope.runMethod = _runMethod;

		interceptorVarScope.interceptedMethods = arguments.interceptor.methods;

		interceptorVarScope.nextInterceptor = "";


		// Add a link in the call chain from the previous interceptor to the one just added.
		if (arrayLen(variables.aroundInterceptors) > 1)
		{
			prevInterceptor = variables.aroundInterceptors[arrayLen(variables.aroundInterceptors) - 1];

			prevInterceptor.bean._v = _liftVariablesScope;
			interceptorVarScope = prevInterceptor.bean._v();

			interceptorVarScope.nextInterceptor = arguments.interceptor.bean;

			structDelete(prevInterceptor.bean, "_v");
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

		arguments.interceptor.bean._v = _liftVariablesScope;

		interceptorVarScope = arguments.interceptor.bean._v();
		interceptorVarScope.preName = variables.preName;
		interceptorVarScope.interceptedMethods = arguments.interceptor.methods;
		interceptorVarScope.translateArgs = _translateArgs;


		if (hasAroundMethod(arguments.interceptor))
		{
			augmentAroundInterceptor(arguments.interceptor);
		}

		structDelete(arguments.interceptor.bean, "_v");
	}


	/** Returns whether a method's access is public or private. */
	private string function getMethodAccess(any method)
	{
		var access = "public";

		if (structKeyExists(getMetadata(method), "access") && getMetadata(method).access == "private")
		{
			access = "private";
		}

		return access;
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


	/** Alters the target bean by adding intercept points. */
	private void function morphTargetBeanInterceptedMethods()
	{
		var access = "";
		var key = "";
		var method = "";
		var varScope = "";


		// Replace intercepted methods on 'this' scope of target bean
		for (key in variables.targetBean)
		{
			// Only alter methods that should be intercepted.
			if ((variables.interceptedMethods == "*" || listFindNoCase(variables.interceptedMethods, key)) && isCustomFunction(variables.targetBean[key]))
			{
				method = variables.targetBean[key];

				variables.targetBean[variables.preName & key] = method;
				variables.targetBean[key] = __callPublicMethod;
			}
		}


		variables.targetBean._v = _liftVariablesScope;
		varScope = variables.targetBean._v();


		// Replace intercepted methods on 'variables' scope of target bean
		for (key in varScope)
		{
			// Only alter methods that should be intercepted.
			if ((variables.interceptedMethods == "*" || listFindNoCase(variables.interceptedMethods, key)) && isCustomFunction(varScope[key]))
			{
				method = varScope[key];
				access = getMethodAccess(method);

				varScope[variables.preName & key] = method;

				if (access == "public")
				{
					varScope[key] = __callPublicMethod;
				}
				else
				{
					varScope[key] = __callPrivateMethod;
				}
			}
		}


		varScope.beanProxy = this;
		varScope.callStacks = __callStacks;
		varScope.preName = variables.preName;
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


	private function runAfterStack(any targetBean, string methodName, struct args, any result)
	{
		if (structKeyExists(arguments, "result") && !isNull(arguments.result))
		{
			local.result = arguments.result;
		}


		for (local.interceptor in variables.afterInterceptors)
		{
			if (methodMatches(methodName, local.interceptor.methods))
			{
				local.tempResult = local.interceptor.bean.after(arguments.targetBean, arguments.methodName, args, isNull(arguments.result) ? javacast("null", 0) : arguments.result);
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


	private function runAroundStack(any targetBean, string methodName, struct args)
	{
		if (arrayLen(variables.aroundInterceptors))
		{
			// Only need to call the first one in the chain to start the process.
			local.result = variables.aroundInterceptors[1].bean.preAround(arguments.targetBean, arguments.methodName, arguments.args);
		}
		else
		{
			local.result = _runMethod(arguments.targetBean, arguments.methodName, arguments.args);
		}

		if (structKeyExists(local, "result") and !isNull(local.result)) return local.result;
	}


	private function runBeforeStack(any targetBean, string methodName, struct args)
	{
		var inteceptor = "";

		for (inteceptor in variables.beforeInterceptors)
		{
			if (structKeyExists(inteceptor.bean, "before"))
			{
				if (methodMatches(methodName, inteceptor.methods))
				{
					inteceptor.bean.before(targetBean, methodName, args);
				}
			}
		}
	}


	private function runOnErrorStack(any targetBean, string methodName, struct args, any exception)
	{
		var interceptor = "";

		for (interceptor in variables.errorInterceptors)
		{
			if (methodMatches(methodName, interceptor.methods))
			{
				interceptor.bean.onError(targetBean, methodName, args, exception);
			}
		}
	}


	/** Creates 'set' methods on the proxy bean to mimic the 'set' methods on the target bean. */
	private function setupSetMethods()
	{
		var key = "";

		for (key in variables.targetBean)
		{
			if (left(key, 3) == "set")
			{
				this[key] = __callPublicMethod;
			}
		}
	}
}