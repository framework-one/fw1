component {
    variables._fw1_version = "3.0_snapshot";
    variables._ioclj_version = "1.0_snapshot";
/*
    Copyright (c) 2015, Sean Corfield

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

    function init( any fw, any cfmljure, any ns ) {
        variables.fw = fw;
        variables.cfmljure = cfmljure;
        variables.ns = ns;
        return this;
    }

    function onMissingMethod( string missingMethodName, struct missingMethodArguments ) {
        if ( structKeyExists( missingMethodArguments, "method" ) &&
             missingMethodArguments.method == "item" ) {
            var rc = missingMethodArguments.rc;
            try {
                var result = variables.cfmljure.toCFML(
                    variables.ns[ missingMethodName ]( variables.cfmljure.toClojure( rc ) )
                );
                structClear( rc );
                structAppend( rc, result );
                // post-process special keys in rc for abort / redirect etc
            } catch ( java.lang.IllegalStateException e ) {
                if ( e.message.startsWith( "Attempting to call unbound fn" ) ) {
                    // no such controller method - ignore it
                } else {
                    throw e;
                }
            }
        }
    }

}
