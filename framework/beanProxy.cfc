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
component {

    variables.interceptors = [];
    variables.targetBean = ""; //the actual bean 
    variables.methodList = ""; //A list of methods. if blank defaults to * (which means all);

    function init( any targetBean, array interceptors = [] ) {
        variables.targetBean = targetBean;
        variables.interceptors = interceptors;
    }

    function onMissingMethod( string missingMethodName, struct missingMethodArguments ) {

        var organizedArgs = cleanupArguments( missingMethodName, missingMethodArguments );
        var result = "";
        try {
            if ( !hasAround() ) {
                runBeforeStack( missingMethodName, organizedArgs, variables.targetBean );
                // because ACF doesn't support direct method invocation :(
                result = evaluate( "variables.targetBean.#arguments.missingMethodName#(argumentCollection=organizedArgs)" );
                runAfterStack(
                    isNull( result ) ? javaCast( "null", 0 ) : result,
                    missingMethodName, organizedArgs, variables.targetBean
                );
            } else {
                result = runAroundStack( missingMethodName, organizedArgs, variables.targetBean );
            }
            if ( !isNull( result ) ) return result;

        } catch ( any e ) {

            if ( !hasErrorStack() ) { rethrow; }
            runOnErrorStack( missingMethodName, organizedArgs, variables.targetBean, e );
        }
    }

    private struct function cleanupArguments( string methodName, struct args ) {
        var organizedArgs = { };
        var positionCount = 1;
        var targetArgInfo = getMetaData( variables.targetBean[ methodName ] ).parameters;
        for ( var p in args ) {
            //They are usually numeric here
            var keyName = positionCount;
            if ( isNumeric( p ) && p <= arrayLen( targetArgInfo ) ) {
                keyname = targetArgInfo[ p ].name;
            }
            organizedArgs[ keyname ] = args[ p ];
            ++positionCount;

        }
        return organizedArgs;
    }

    /*
	SEARCHING functions
    */
    private boolean function hasAround() {
        for ( var inter in variables.interceptors ) {
            if ( structKeyExists( inter.bean, "around" ) ) {
                return true;
            }
        }
        return false;
    }

    private boolean function hasErrorStack() {
        for ( var inter in variables.interceptors ) {
            if ( structKeyExists( inter.bean, "onError" ) )  {
                return true;
            }
        }
        return false;
    }

    private function getAroundInterceptorCount( string methodName ) {
        var total = 0;
        for ( var inter in variables.interceptors ) {
            if ( structKeyExists( inter.bean, "around" ) &&
                 methodMatches( methodName, inter.methods ) ) {
                ++total;
            }
        }
        return total;
    }

    /*
	Functions that run all the interceptors
    */
    private function runBeforeStack( string methodName, string args, any targetBean ) {
        for ( var inter in variables.interceptors ) {
            if ( structKeyExists( inter.bean, "before" ) ) {
                if ( methodMatches( methodName, inter.methods ) )  {
                    inter.bean.before( methodName, args, targetBean );
                }
            }
        }
    }

    private function runAroundStack( string methodName, struct args, any targetBean ) {
        var result = "";
        var totalInterceptors = getAroundInterceptorCount( methodName );
        var hitCount = 1;
        for ( var inter in variables.interceptors ) {
            if ( structKeyExists( inter.bean, "around" ) ) {
                if ( !methodMatches( methodName, inter.methods ) ) {
                    continue;
                }
                inter.bean.last = hitCount == totalInterceptors;
                result = inter.bean.around( methodName,  args, targetBean );
                ++hitCount;
            }
        }
        if ( !isNull( result ) ) return result;
    }

    private function runAfterStack( any result, string methodName, struct args, any targetBean ) {
        for ( var inter in variables.interceptors ) {
            if ( structKeyExists( inter.bean, "after" ) ) {
                if ( !methodMatches( methodName, inter.methods ) ) {
                    continue;
                }
                inter.bean.after(
                    isNull( result ) ? javaCast( "null", 0 ) : result,
                    methodName, args, targetBean
                );
            }
        }
    }

    private function runOnErrorStack( string methodName, string organizedArgs, any targetBean, any error ) {
        for ( var inter in variables.interceptors ) {
            if ( structKeyExists( inter.bean, "onError" ) ) {
                if ( !methodMatches( methodName, inter.methods ) ) {
                    continue;
                }
                inter.bean.onError( methodName, organizedArgs, targetBean, error );
            }
        }
    }

    public boolean function methodMatches( string methodName, string matchers ) {
        if ( !listLen( matchers ) ) {
            return true;
        }
        if ( methodName == matchers ) {
            return true;
        }
        if ( listFindNoCase( matchers, methodName, ",", false ) ) {
            return true;
        }
        return false;
    }

}
