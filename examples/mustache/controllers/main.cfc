component accessors=true {

    property framework;

    function default( rc ) {
        rc.numbers = [1,2,3,4];
        framework.renderData( "mustache" );
    }

}
