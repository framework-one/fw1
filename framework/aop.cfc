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

    // ADDITIONAL INTERNAL STATE
    variables.interceptInfo = { };

    // PUBLIC METHODS

    public any function intercept( string beanName, string interceptorName, string methodNames = "" ) {
        if ( !structKeyExists( variables.interceptInfo, beanName ) )  {
            variables.interceptInfo[ beanName ] = [ ];
        }
        var interceptionDefinition = {
            name = interceptorName,
            methods = methodNames
        };
        arrayAppend( variables.interceptInfo[ beanName ], interceptionDefinition );
        return this;
    }

    // PRIVATE IMPLEMENTATION

    // used to pull beans apart for transgenesis
    public struct function liftVariablesScope() {
        return variables;
    }

    private void function moveBeanTo( any oldBean, any newBean ) {
        oldBean._v = liftVariablesScope;
        structAppend( newBean, oldBean ); // copy THIS scope
        // then copy VARIABLES scope
        structAppend( newBean._v(), oldBean._v() );
        // then clear old VARIABLES scope
        structClear( oldBean._v() );
        // then clear old THIS scope
        structClear( oldBean );
    }

    private void function setupInitMethod( string beanName, any bean ) {
        // if it doesn't have a dotted path for us to create a new instance
        // or it has no interceptors, we have to leave it alone
        if ( !structKeyExists( variables.beanInfo, beanName ) ||
             !structKeyExists( variables.beanInfo[ beanName ], 'cfc' ) ||
             !structKeyExists( variables.interceptInfo, beanName ) ) {
            return;
        }
        // create the new state/method holder:
        var newBean = construct( variables.beanInfo[ beanName ].cfc );
        moveBeanTo( bean, newBean );
        // build the interceptor array:
        var interceptors = [];
        for ( var inter in variables.interceptInfo[ beanName ] ) {
            var interceptorPacket = {
                bean = getBean( inter.name ),
                methods = inter.methods
            };
            arrayAppend( interceptors, interceptorPacket );
        }
        var proxy = new framework.beanProxy( newBean, interceptors );
        moveBeanTo( proxy, bean );
    }

}
