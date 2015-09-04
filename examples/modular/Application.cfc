component extends=framework.one {
    variables.framework = {
        controllersFolder : "handlers",
        layoutsFolder : "wrappers",
        subsystemsFolder : "plugins",
        viewsFolder : "pages"
    };
    function setupView( rc ) {
        rc.message = "Rendered by FW/1 version " & variables.framework.version;
    }
}
