component extends="framework.ioc" {
    variables._fw1_version = "3.1-rc1";
    variables._aop1_version = "2.0-rc1";
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


	private any function construct(string dottedPath)
	{
		var bean = super.construct(arguments.dottedPath);
		var beanName = listLast(arguments.dottedPath, ".");


		// if it doesn't have a dotted path for us to create a new instance
		// or it has no interceptors, we have to leave it alone
		if (!hasInterceptors(beanName))
		{
			return bean;
		}

		// Create and return a proxy wrapping the bean.
		return createProxy(beanName, bean);
	}


	/** Augments the original bean by gutting it and replacing it's scopes with the proxy bean. */
	private any function createProxy(string beanName, any bean)
	{
		var beanProxy = new framework.beanProxy(bean, getInterceptorsForBean(arguments.beanName), variables.config);

		return beanProxy;
	}


	/** Gets the associated interceptor definitions for a specific bean. */
	private array function getInterceptorsForBean(string beanName)
	{
		// build the interceptor array:
		var aliases = getAliases(arguments.beanName);
		var interceptDefinition = "";
		var interceptedBeanName = "";
		var interceptors = [];


		arrayPrepend(aliases, arguments.beanName);


		for (interceptedBeanName in aliases)
		{
			if (structKeyExists(variables.interceptInfo, interceptedBeanName))
			{
				for (interceptDefinition in variables.interceptInfo[interceptedBeanName])
				{
					arrayAppend(interceptors, {bean = getBean(interceptDefinition.name), methods = interceptDefinition.methods});
				}
			}
		}

		return interceptors;
	}


	/** Determines if the bean has interceptor definitions associated with it. */
	private boolean function hasInterceptors(string beanName)
	{
		var interceptedBeanName = "";

		// Straight up match in the interceptors.
		if (structKeyExists(variables.interceptInfo, arguments.beanName))
		{
			return true;
		}


		// Look for matches on aliases.
		for (interceptedBeanName in getAliases(arguments.beanName))
		{
			if (structKeyExists(variables.interceptInfo, interceptedBeanName))
			{
				return true;
			}
		}


		return false;
	}


	/** Finds all aliases for the given beanName. */
	private array function getAliases(string beanName)
	{
		var aliases = [];
		var beanData = "";
		var key = "";


		if (structKeyExists(variables.beanInfo, arguments.beanName))
		{
			beanData = variables.beanInfo[arguments.beanName];

			for (key in variables.beanInfo)
			{
				// Same cfc dotted path, must be an alias.
				if (
						key != arguments.beanName && 
						structKeyExists(variables.beanInfo[key], "cfc") && 
						structKeyExists(variables.beanInfo[arguments.beanName], "cfc") && 
						variables.beanInfo[key].cfc == variables.beanInfo[arguments.beanName].cfc)
				{
					arrayAppend(aliases, key);
				}
			}
		}

		return aliases;
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


	private void function setupFrameworkDefaults()
	{
		super.setupFrameworkDefaults();
		variables.config.version = variables._aop1_version & " (" & variables._di1_version & ")";
	}
}