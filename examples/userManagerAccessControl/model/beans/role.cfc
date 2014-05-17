component accessors=true {

    property id;
    property name;

    function init( string id = 0, string name = "" ) {
        variables.id = id;
        variables.name = name;
        return this;
    }
}
