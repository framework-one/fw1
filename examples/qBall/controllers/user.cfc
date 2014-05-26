component accessors="true" {

    property user;

    function init(fw) {
        variables.fw = fw;
    }

    function checkAuthorization(rc) {
        rc.authenticated = structKeyExists(session, "userid");
        if(rc.authenticated) {
            rc.user = variables.user.get(session.userid);
        }
    }

    function authenticate(rc) {
        rc.loginerrors = [];
        if(!len(trim(rc.username))) {
            arrayAppend(rc.loginerrors, "You must include a username.");
        }

        if(!len(trim(rc.password))) {
            arrayAppend(rc.loginerrors, "You must include a password.");
        }

        if(arrayLen(rc.loginerrors)) {
            variables.fw.redirect("user.login", "username,loginerrors");
        }
        rc.user = variables.user.authenticate(rc.username, rc.password);

        if(!structKeyExists(rc, "user")) {
            rc.loginerrors[1] = "Your login failed.";
            variables.fw.redirect("user.login", "username,loginerrors");
        } else {
            //Result is a user entity, but we only persist the ID
            session.auth.isloggedin = true;
            session.auth.userid = rc.user.getId();
            variables.fw.redirect("main.default");

        }

            session.auth.isloggedin = true;
    }

    function logout(rc) {
        session.auth.isloggedin = false;

        variables.fw.redirect("main.default");
    }

    function register(rc) {
        rc.registererrors = [];
        if(!len(trim(rc.username))) {
            arrayAppend(rc.registererrors, "You must include a username.");
        }
        if(!len(trim(rc.password))) {
            arrayAppend(rc.registererrors, "You must include a password.");
        }
        if(rc.password2 != rc.password) {
            arrayAppend(rc.registererrors, "Your confirmation password did not match.");
        }
        if(!isValid("email", rc.email)) {
            arrayAppend(rc.registererrors, "You must include a valid email address.");
        }

        if(arrayLen(rc.registererrors)) {
            variables.fw.redirect("user.login", "username,email,registererrors");
        }

        rc.data = rc.registererrors;
        if(isSimpleValue(rc.data)) {
            rc.registererrors[1] = rc.data;
            variables.fw.redirect("user.login", "username,email,registererrors");
        } else {
            //Result is a user entity, but we only persist the ID

            addUser = variables.user.register(rc.username, rc.password, rc.email);

            session.userid = addUser.getId();
            variables.fw.redirect("main.default");
        }
    }

}
