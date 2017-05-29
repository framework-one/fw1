component {

    function init( any fw ) {
        variables.fw = fw;
        return this;
    }

    function patch( struct rc, struct headers ) {
        var response = {
            "method": "PATCH",
            "multi": rc.multi,
            "single": rc.single
        };
        variables.fw.renderData().type( 'json' ).data( response );
    }

    function post( struct rc, struct headers ) {
        var response = {
            "method": "POST",
            "multi": rc.multi,
            "single": rc.single
        };
        variables.fw.renderData().type( 'json' ).data( response );
    }

    function put( struct rc, struct headers ) {
        var response = {
            "method": "PUT",
            "multi": rc.multi,
            "single": rc.single
        };
        variables.fw.renderData().type( 'json' ).data( response );
    }

}
