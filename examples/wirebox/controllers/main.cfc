component accessors="true" {

    property friendlyservice;

    function default( rc ) {
        rc.message = variables.friendlyservice.greeting();
    }

}
