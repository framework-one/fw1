component accessors="true" {
    property name="DSN";
    property name="ID";
    property name="name";

    public any function init( dsn, ID = 0,  NAME = "Bob") {
        variables.dsn = dsn;
        variables.ID = ID;
        variables.name = name;
        return this;
    }
}
