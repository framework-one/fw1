component accessors=true {
    property framework;
    function default( rc ) {
        rc.handlerSays = "This message brought to you by " &
            framework.getConfig().controllersFolder & "/main.cfc!";
    }
}
