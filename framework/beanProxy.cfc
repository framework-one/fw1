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
component output="false" displayname="beanProxy"  {

	variables.interceptors = [];
	variables.targetBean = ""; //the actual bean 
	variables.methodList = ""; //A list of methods. if blank defaults to * (which means all);
	

	function init(Component targetBean, Array interceptors = []){
		variables.targetBean = arguments.targetBean;
		variables.interceptors = arguments.interceptors;
	}

	public function onMissingMethod(missingMethodName,missingMethodArguments){


		var organizedArgs = cleanupArguments(arguments.missingMethodName,arguments.missingMethodArguments);
		var result = "";
		try{
			
			if(!hasAround()){
				runBeforeStack(arguments.missingMethodName, organizedArgs, variables.targetBean);
                // because ACF doesn't support direct method invocation :(
				result = evaluate("variables.targetBean.#arguments.missingMethodName#(argumentCollection=organizedArgs)");
				runAfterStack(local.result , arguments.missingMethodName, local.organizedArgs, variables.targetBean);

			}
			else{
				result = runAroundStack(arguments.missingMethodName, local.organizedArgs, variables.targetBean);
			}

			return result;
		}catch(Any e){

			if(!hasErrorStack()){ rethrow; }

			runOnErrorStack(arguments.missingMethodName, local.organizedArgs, variables.targetBean, e);
		}
	}

	private function cleanupArguments(methodName, args){
		var organizedArgs = {};
		var positionCount = 1;
		var p = "";
		var targetArgInfo = getMetaData(variables.targetBean[arguments.methodName]).parameters;
        for ( p in arguments.args ) {
			//They are usually numeric here
			var keyName = positionCount;
			if(isNumeric(p) && p LTE ArrayLen(targetArgInfo)){
				keyname = targetArgInfo[p].name;
			}
			organizedArgs[keyname] = arguments.args[p];
			positionCount++;

		}
		return organizedArgs;
	}

/*
	SEARCHING functions
*/
	private function hasAround(){
		for(var inter in variables.interceptors){
			if(StructKeyExists(inter.bean, "around")){
				return true;
			}
		}
		return false;
	}
	private function hasErrorStack(){

		//loop through the interceptros finding the error methods;

		for(var inter in variables.interceptors){
			if(StructKeyExists(inter.bean, "onError")){
				return true;
			}	
		}
		return false;
	}

	private function getAroundInterceptorCount(){
		var total = 0;
		for(var inter in variables.interceptors){
			if(StructKeyExists(inter.bean, "around")){
				total++;
			}
		}
		return total;
	}
/*
	Functions that run all the interceptors
*/	


	private function runBeforeStack(methodName, args, targetBean){

		for(var inter in variables.interceptors){
			if(StructKeyExists(inter.bean, "before")){

				if(methodMatches(arguments.methodName, inter.methods)){
					inter.bean.before(arguments.methodName, arguments.args, arguments.targetBean);
				}
			}
		}
	}

	private function runAroundStack(methodName, args, targetBean) {
		var result = "";
		var totalInterceptors = getAroundInterceptorCount();

		//count around intercept
		var hitCount = 1;
	
		for(var inter in variables.interceptors){
			if(StructKeyExists(inter.bean, "around")){
				if(!methodMatches(arguments.methodName, inter.methods)){
					continue;
				}
				if(hitCount EQ totalInterceptors){
					inter.bean.last = true;
				}
				else{
					inter.bean.last = false;
					
				}
				result = inter.bean.around(arguments.methodName, arguments.args, arguments.targetBean);
				hitCount++;
				
			}
		}
		
		return result;
	}

	private function runAfterStack(result, methodName, args, targetBean) {
		for(var inter in variables.interceptors){
			if(StructKeyExists(inter.bean, "after")){
				if(!methodMatches(arguments.methodName, inter.methods)){
					continue;
				}

				var retvar = inter.bean.after(arguments.result, arguments.methodName, arguments.args, arguments.targetBean);
			}
		}
	}

	private function runOnErrorStack(methodName, organizedArgs, targetBean, error) {

		for(var inter in variables.interceptors){
			if(StructKeyExists(inter.bean, "onError")){
				if(!methodMatches(arguments.methodName, inter.methods)){
					continue;
				}
				result = inter.bean.onError(arguments.methodName, arguments.organizedArgs, arguments.targetBean, arguments.error);

			}
		}
	}
	
	public boolean function methodMatches (methodName, matchers) output=false{
		
		//Empty list
		if(!ListLen(arguments.matchers)){
			return true;
		}
		
		if(arguments.methodName EQ arguments.matchers){
			return true;
		}

	
		if(listFindNoCase(arguments.matchers, arguments.methodName, ",", false)){

			return true;
		}
		return false;
	}
	
	

	

	 
	
	
}
