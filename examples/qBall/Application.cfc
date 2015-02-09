component extends="framework.one" {

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

    variables.framework = {
        diLocations = "./model/services", // ColdFusion ORM handles Beans
        reloadApplicationOnEveryRequest = "true",
        trace = "false"
    };

    public function setupSession() {
        controller('security.session');
    }

    public function setupRequest() {
        if(structKeyExists(url, "init")) { // use index.cfm?init to reload ORM
            setupApplication();
            ormReload();
            location(url="index.cfm",addToken=false);
        }

        controller("security.authorize");

    }

}
