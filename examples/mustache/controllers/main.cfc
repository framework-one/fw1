component {

    function default( rc ) {
        rc.numbers = [1,2,3,4];
        rc.productversion =
            server.coldfusion.productname & " " &
            ( structKeyExists( server, "lucee" ) ?
                server.lucee.version & " / " : "" ) &
            server.coldfusion.productversion;
    }

}
