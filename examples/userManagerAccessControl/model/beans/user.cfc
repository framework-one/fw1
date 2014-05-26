component accessors=true {

    property id;
    property firstname;
    property lastname;
    property email;
    property department;
    property departmentid;
    property role;
    property roleid;
    property passwordHash;
    property passwordSalt;

    function init( string id = 0, string firstname = "", string lastname = "", string email = "",
                   any department = "", any role = "", string passwordHash = "", string passwordSalt = "" ) {
        variables.id = id;
        variables.firstname = firstname;
        variables.lastname = lastname;
        variables.email = email;
        variables.department = department;
        if ( isObject( department ) ) {
            variables.departmentid = department.getId();
        } else {
            variables.departmentid = "";
        }
        variables.role = role;
        if ( isObject( role ) ) {
            variables.roleid = role.getId();
        } else {
            variables.roleid = 2; // default role id is user
        }
        variables.passwordHash = passwordHash;
        variables.passwordSalt = passwordSalt;
        return this;
    }
}
