component {
    variables._fw1_version = "4.3.0";
/*
    Copyright (c) 2016-2018, Sean Corfield

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

    function init() {
        try {
            return request._fw1.theFramework;
        } catch ( any e ) {
            throw(
                type = "FW1.FacadeException", message = "Unable to locate FW/1 for this request",
                detail = "It appears that you asked for the facade in a request that did not originate in FW/1?"
            );
        }
    }

}
