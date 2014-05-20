/**
 * I am the User service.
 */
component {

    variables.lock_name = "userlock";

    public any function authenticate(string username, string password) {
        writeLog(file='application',text='checking #username#/#password#');
        var user = entityLoad("user", {username=#username#, password=#password#},true);
        if(!isNull(user)) {
            session.auth.userid = user.getId();
            session.auth.username = user.getUserName();
            return user;
        }
    }

    public boolean function exists(string username) {
        var userCheck = entityLoad("user", {username=arguments.username});
        if(arrayLen(userCheck) == 1) return true;
        return false;
    }

    public function get(numeric id) {
        return entityLoadByPk("user", arguments.id);
    }

    public any function register(string username,string password, string email) {
        writeLog(file='application',text='running SERVICE user.register() #serializejson(arguments)#');
        lock name="#variables.lock_name#" type="exclusive" timeout=30 {
            if(exists(arguments.username)) return "User already exists.";
            var user = entityNew("user");
            user.setUsername(arguments.username);
            user.setPassword(arguments.password);
            user.setEmailAddress(arguments.email);
            entitySave(user);
            return user;
        }
    }

}
