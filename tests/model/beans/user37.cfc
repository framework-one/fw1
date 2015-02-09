component accessors="true" {
    property name="DSN";
    property name="ID";
    public any function init( dsn, ID = 0 ) {
        variables.dsn = dsn;
        variables.ID = ID;
        return this;
    }
}
