component {
    function init() {
        param name="application.userServiceCount" default="0";
        variables.id = ++application.userServiceCount;
    }
	function getId() {
        return variables.id;
    }
}
