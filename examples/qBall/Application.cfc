component extends="org.corfield.framework" {

    this.name = "qball";
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0,2,0,0);
    this.dataSource = this.name;
    this.ormEnabled = true;
    this.ormsettings = {
        cfclocation="./model/beans",
        dbcreate="dropcreate",
        /*dbcreate="update",*/
        /*dialect="MySQL",*/
        dialect="Oracle10G",
        //eventhandling="true",
        //eventhandler="model.beans.eventHandler",
        logsql="true"
    };


    variables.framework = {
        reloadApplicationOnEveryRequest = "true",
        trace = "false"
    };

    public function setupSession() {
        controller('security.session');
    }

    public function setupApplication() {
        var bf = new framework.ioc("./model/services");
        setBeanFactory(bf);
    }

    public function setupRequest() {
        if(structKeyExists(url, "init")) {
            setupApplication();
            ormReload();
            location(url="index.cfm",addToken=false);
        }

        controller("security.authorize");

    }

}
