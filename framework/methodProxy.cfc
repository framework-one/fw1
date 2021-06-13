component {
    variables._fw1_version = "4.3.0";
    /*
      Copyright (c) 2018, Sean Corfield

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

    function init( fw, method ) {
        variables.fw = fw;
        variables.method = method;
        return this;
    }

    // implements Java 8 Function interface
    function apply( arg ) {
        return invoke( variables.fw, method, [ arg ] );
    }

}
