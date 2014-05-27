component {

    function init() {
        variables.loaded = false;
    }

    function onLoad( any factory ) {
        variables.loaded = true;
    }

    function isLoaded() {
        return variables.loaded;
    }
   
}
