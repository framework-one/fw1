component accessors=true {
    property framework;
    function default( rc ) {
        rc.message = "Rendered by FW/1 version " & framework.getConfig().version;
    }
}
