component extends="framework.ioc" {
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
	variables.interceptInfo = { }; // Internal cache of interceptor definitions.




	// -------------- //
	// PUBLIC METHODS //
	// -------------- //

	/** Constructor. */
	public any function init(string folders, struct config = {})
	{
		super.init(argumentCollection = arguments);

		if (structKeyExists(arguments.config, "interceptors") && isArray(arguments.config.interceptors) && arrayLen(arguments.config.interceptors))
		{
			loadInterceptors(arguments.config.interceptors);
		}
	}


	/** Adds an interceptor definition to the definition cache. */
	public any function intercept(string beanName, string interceptorName, string methods = "")
	{
		var interceptDefinition =
		{
			name = arguments.interceptorName,
			methods = arguments.methods
		};


		if (!structKeyExists(variables.interceptInfo, arguments.beanName))
		{
			variables.interceptInfo[arguments.beanName] = [];
		}

		arrayAppend(variables.interceptInfo[arguments.beanName], interceptDefinition);

		return this;
	}




	// --------------- //
	// PRIVATE METHODS //
	// --------------- //

	// Used to augment the bean and makes the variables scope of the bean accessible for transgenesis
	public struct function _liftVariablesScope()
	{
		return variables;
	}


	/** Augments the original bean by gutting it and replacing it's scopes with the proxy bean. */
	private void function augmentBean(string beanName, any bean)
	{
		var beanProxy = "";
		var newBean = "";


		// create the new state/method holder:
		newBean = construct(variables.beanInfo[beanName].cfc);
		moveBeanTo(bean, newBean, true);


		// Setup the proxy
		beanProxy = new framework.beanProxy(newBean, getInterceptorsForBean(arguments.beanName));
		moveBeanTo(beanProxy, bean, false);

		// Called here to maintain proper scopes.
		bean.morphTargetBeanInterceptedMethods();
	}


	/** Copies variables and methods from one source structure to a target structure. */
	private void function copyScope(struct source, struct target, boolean skipFunctions)
	{
		var key = "";
		var value = "";


		for (key in arguments.source)
		{
			value = arguments.source[key];

			if (!arguments.skipFunctions || (arguments.skipFunctions && isCustomFunction(value)))
			{
				target[key] = value;
			}
		}
	}


	/** Gets the associated interceptor definitions for a specific bean. */
	private array function getInterceptorsForBean(string beanName)
	{
		// build the interceptor array:
		var interceptDefinition = "";
		var interceptors = [];

		for (interceptDefinition in variables.interceptInfo[beanName])
		{
			arrayAppend(interceptors, {bean = getBean(interceptDefinition.name), methods = interceptDefinition.methods});
		}

		return interceptors;
	}


	/** Determines if the bean has interceptor definitions associated with it. */
	private boolean function hasInterceptors(string beanName)
	{
		return structKeyExists(variables.interceptInfo, arguments.beanName);
	}


	/** Loads an array of interceptor definitions into the interceptor definition cache. */
	private void function loadInterceptors(array interceptors)
	{
		var interceptor = false;

		for (interceptor in interceptors)
		{
			 intercept(argumentCollection = interceptor);
		}
	}


	/** Moves all the state data and methods from a source bean to a target bean. Clears out the source bean. */
	private void function moveBeanTo(any sourceBean, any targetBean, boolean skipFunctions)
	{
		var key = "";
		var source = "";
		var target = "";
		var value = "";

		arguments.targetBean._v = _liftVariablesScope;
		arguments.sourceBean._v = _liftVariablesScope;


		// copy THIS scope
		copyScope(arguments.sourceBean, arguments.targetBean, arguments.skipFunctions);


		// then copy VARIABLES scope
		copyScope(arguments.sourceBean._v(), arguments.targetBean._v(), arguments.skipFunctions);


		// then clear old VARIABLES scope
		structClear(arguments.sourceBean._v());

		// then clear old THIS scope
		structClear(arguments.sourceBean);
	}


	private void function setupFrameworkDefaults()
	{
		super.setupFrameworkDefaults();
		variables.config.version = variables._aop1_version & " (" & variables._di1_version & ")";
	}


	/** Hook point to intercept beans and augment them if they are to be intercepted. */
	private void function setupInitMethod(string beanName, any bean)
	{
		// if it doesn't have a dotted path for us to create a new instance
		// or it has no interceptors, we have to leave it alone
		if (!structKeyExists(variables.beanInfo, beanName) || !structKeyExists(variables.beanInfo[beanName], "cfc") || !hasInterceptors(arguments.beanName))
		{
			return;
		}


		// Alter the original bean to now be a proxy.
		augmentBean(arguments.beanName, arguments.bean);
	}
}
