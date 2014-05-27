component accessors="true" {
    property name="DSN";
    property name="ID";

    // to reveal an ordering bug changed ID to cd just so it comes before dsn
    public any function init( dsn, cd = 0 ) {
        variables.dsn = dsn;
        variables.ID = cd;
        return this;
    }
}
