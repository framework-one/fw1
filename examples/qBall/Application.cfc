component {
    this.mappings[ '/framework' ] = expandPath( '../../framework' );    
    this.name = "qball";
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0,2,0,0);
    this.dataSource = this.name;
    this.ormEnabled = true;
    this.ormsettings = {
        cfclocation="./model/beans",
        dbcreate="update",       // update database tables only
        dialect="MySQL",         // assume MySql, other dialects available http://help.adobe.com/en_US/ColdFusion/9.0/Developing/WSED380324-6CBE-47cb-9E5E-26B66ACA9E81.html
        eventhandling="true",
        eventhandler="root.model.beans.eventhandler",
        logsql="true"
    };
    this.mappings["/root"] = getDirectoryFromPath(getCurrentTemplatePath());
    
    function _get_framework_one() {
        if ( !structKeyExists( request, '_framework_one' ) ) {

            // create your FW/1 application:
            request._framework_one = new MyApplication();
        }
        return request._framework_one;
    }

    // delegation of lifecycle methods to FW/1:
    function onApplicationStart() {
        return _get_framework_one().onApplicationStart();
    }
    function onError( exception, event ) {
        return _get_framework_one().onError( exception, event );
    }
    function onRequest( targetPath ) {
        return _get_framework_one().onRequest( targetPath );
    }
    function onRequestEnd() {
        return _get_framework_one().onRequestEnd();
    }
    function onRequestStart( targetPath ) {
        return _get_framework_one().onRequestStart( targetPath );
    }
    function onSessionStart() {
        return _get_framework_one().onSessionStart();
    }
}
