/*
	Copyright (c) 2013-2014, Mark Drew, Sean Corfield

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
component extends="framework.ioc" {

	variables.bf = ""; // our beanFactory

	variables.iStack = {}; //Interceptor stack. This keeps a list of who is intercepting what

	variables.proxies = {};

	function init(){
		super.init(argumentCollection=arguments);
		return this;
	}

	/*
		returns the original beanFactory
	*/
	function getIOC(){
		return variables.bf;
	}

	function intercept(beanName, interceptorName, methodnames=""){

		if(!StructKeyExists(variables.iStack, arguments.beanName)){
			variables.iStack[arguments.beanName] = ArrayNew(1);
		}

		var InterceptionDefinition = {
				name = arguments.interceptorName,
				methods = arguments.methodNames
		};

		ArrayAppend(variables.iStack[arguments.beanName], InterceptionDefinition);


		return this;
	}

	function hasInterceptors(String BeanName){

		if(StructKeyExists(variables.iStack, arguments.BeanName) && ArrayLen(variables.iStack[arguments.BeanName])){
			return true;
		}

		return false;
	}


	function getInterceptors(String BeanName){
		if(StructKeyExists(variables.iStack, arguments.BeanName)){
			return variables.iStack[arguments.BeanName];
		}
		return [];
	}


	function getBean(BeanName){
		//IF it doesn't have Interceptors just call it au-naturel
		if(!hasInterceptors(arguments.BeanName)){
			return super.getBean(arguments.BeanName);
		}
		
		//It has interceptors so return the beanProxy
		var targetBean = super.getBean(arguments.BeanName);

		//let's go get and instantiate the interceptors!
		var interceptors= [];

		for(var inter in getInterceptors(arguments.BeanName)){

			var interceptorPacket = {bean = super.getBean(inter.name), methods = inter.methods} ;
			ArrayAppend(interceptors,interceptorPacket);
		}
		var beanProxy = new framework.beanProxy(targetBean, interceptors);

		return beanProxy ;

	}

}
