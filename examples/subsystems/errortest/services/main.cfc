component {

    function error() {
        return "services/main.cfc:error() was called";
    }

    function default( foo ) {
        // cause an exception by referencing undefined variable bar:
        return foo + bar;
    }

}
