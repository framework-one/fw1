component extends="framework.ioc" {
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
	// Internal cache of interceptor definitions.
	variables.interceptorCache = {regex = [], name = {}, type = []};




	// -------------- //
	// PUBLIC METHODS //
	// -------------- //

	/** Constructor. */
	public any function init(any folders, struct config = {})
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


		arguments.beanName = trim(arguments.beanName);


		// Determine if this is a name match or regex match.
		if (len(arguments.beanName) && left(arguments.beanName, 1) == "/" && right(arguments.beanName, 1) == "/")
		{
			// Store regex without the forward slashes.
			interceptDefinition.regex = mid(arguments.beanName, 2, len(arguments.beanName) - 2);

			arrayAppend(variables.interceptorCache.regex, interceptDefinition);
		}
		else
		{
			if (!structKeyExists(variables.interceptorCache.name, arguments.beanName))
			{
				variables.interceptorCache.name[arguments.beanName] = [];
			}

			arrayAppend(variables.interceptorCache.name[arguments.beanName], interceptDefinition);
		}


		return this;
	}


	/** Adds an interceptor definition to the definition cache. */
	public any function interceptByType(string type, string interceptorName, string methods = "")
	{
		var interceptDefinition =
		{
			type = arguments.type,
			name = arguments.interceptorName,
			methods = arguments.methods
		};

		arrayAppend(variables.interceptorCache.type, interceptDefinition);
	}




	// --------------- //
	// PRIVATE METHODS //
	// --------------- //

	/** Hook point to wrap bean with proxy. */
	private any function construct(string dottedPath)
	{
		var bean = super.construct(arguments.dottedPath);
		var beanProxy = "";

		// if it doesn't have a dotted path for us to create a new instance
		// or it has no interceptors, we have to leave it alone
		if (!hasInterceptors(arguments.dottedPath))
		{
			return bean;
		}

		// Create and return a proxy wrapping the bean.
		beanProxy = new framework.beanProxy(bean, getInterceptorsForBean(arguments.dottedPath), variables.config);

		return beanProxy;
	}


	/** Gets the associated interceptor definitions for a specific bean. */
	private array function getInterceptorsForBean(string dottedPath)
	{
		// build the interceptor array:
		var beanName = listLast(arguments.dottedPath, ".");
		var beanNames = getAliases(arguments.dottedPath);
		var beanTypes = "";
		var interceptDefinition = "";
		var interceptedBeanName = "";
		var interceptors = [];


		arrayPrepend(beanNames, beanName);

		// Removing duplicate beanNames
		beanNames = listToArray(listRemoveDuplicates(arrayToList(beanNames),",",true) );

		// Grab all name based interceptors that match.
		for (interceptedBeanName in beanNames)
		{
			// Match on name.
			if (structKeyExists(variables.interceptorCache.name, interceptedBeanName))
			{
				for (interceptDefinition in variables.interceptorCache.name[interceptedBeanName])
				{
					arrayAppend(interceptors, {bean = getBean(interceptDefinition.name), methods = interceptDefinition.methods});
				}
			}
		}


		// Match on regex.  Ensure we only attach each one time.
		if (arrayLen(variables.interceptorCache.regex))
		{
			for (interceptDefinition in variables.interceptorCache.regex)
			{
				for (interceptedBeanName in beanNames)
				{
					if (reFindNoCase(interceptDefinition.regex, interceptedBeanName))
					{
						arrayAppend(interceptors, {bean = getBean(interceptDefinition.name), methods = interceptDefinition.methods});
						break;
					}
				}
			}
		}


		// Grab all type based interceptors that match.
		if (arrayLen(variables.interceptorCache.type))
		{
			beanTypes = getBeanTypes(arguments.dottedPath);

			for (interceptDefinition in variables.interceptorCache.type)
			{
				if (listFindNoCase(beanTypes, interceptDefinition.type))
				{
					arrayAppend(interceptors, {bean = getBean(interceptDefinition.name), methods = interceptDefinition.methods});
				}
			}
		}


		return interceptors;
	}


	/** Determines if the bean has interceptor definitions associated with it. */
	private boolean function hasInterceptors(string dottedPath)
	{
		var interceptedBeanName = "";
		var interceptorDefinition = {};
		var beanName = listLast(arguments.dottedPath, ".");
		var beanNames = getAliases(arguments.dottedPath);
		var beanTypes = "";


		arrayPrepend(beanNames, beanName);


		for (interceptedBeanName in beanNames)
		{
			// Look for matches on name first.
			if (structKeyExists(variables.interceptorCache.name, interceptedBeanName))
			{
				return true;
			}


			// Look for matches on regex.
			if (arrayLen(variables.interceptorCache.regex))
			{
				for (interceptorDefinition in variables.interceptorCache.regex)
				{
					if (reFindNoCase(interceptorDefinition.regex, interceptedBeanName))
					{
						return true;
					}
				}
			}


			// Look for matches by bean type.
			if (arrayLen(variables.interceptorCache.type))
			{
				beanTypes = getBeanTypes(arguments.dottedPath);

				for (interceptorDefinition in variables.interceptorCache.type)
				{
					if (listFindNoCase(beanTypes, interceptorDefinition.type))
					{
						return true;
					}
				}
			}
		}


		return false;
	}


	/** Finds all aliases for the given dottedPath. */
	private array function getAliases(string dottedPath)
	{
		var aliases = [];
		var beanData = "";
		var key = "";

		for (key in variables.beanInfo)
		{
			// Same cfc dotted path, must be an alias.
			if (
					structKeyExists(variables.beanInfo[key], "cfc") &&
					variables.beanInfo[key].cfc == arguments.dottedPath)
			{
				arrayAppend(aliases, key);
			}
		}

		return aliases;
	}


	/** Returns a list of bean types (both name and dotted path) for a given bean. */
	private string function getBeanTypes(string dottedPath)
	{
		var beanTypes = "";
		var metadata = getComponentMetadata(arguments.dottedPath);

		while (!len(beanTypes) || structKeyExists(metadata, "extends"))
		{
			beanTypes = listAppend(beanTypes, listLast(metadata.name, "."));
			beanTypes = listAppend(beanTypes, metadata.name);

			if (structKeyExists(metadata, "extends"))
			{
				metadata = metadata.extends;
			}
		}

		return beanTypes;
	}


	/** Loads an array of interceptor definitions into the interceptor definition cache. */
	private void function loadInterceptors(array interceptors)
	{
		var interceptor = false;

		for (interceptor in interceptors)
		{
			if (structKeyExists(interceptor, "beanName"))
			{
				intercept(argumentCollection = interceptor);
			}
			else
			{
				interceptByType(argumentCollection = interceptor);
			}
		}
	}


	private void function setupFrameworkDefaults()
	{
		super.setupFrameworkDefaults();
		variables.config.version = variables._fw1_version;
	}
}
