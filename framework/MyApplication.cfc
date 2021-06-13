component extends="framework.one" {
    // Version: FW/1 4.3.0-SNAPSHOT

    // if you need to provide extension points, copy this to
    // your web root, next to your Application.cfc, and add
    // functions to it, then in Application.cfc use:
    //     request._framework_one = new MyApplication( config );
    // instead of:
    //     request._framework_one = new framework.one( config );
    // in the _get_framework_one() function.
    //
    // if you do not need extension points, you can ignore this

    function setupApplication() { }

    function setupEnvironment( env ) { }

    function setupSession() { }

    function setupRequest() { }

    function setupResponse( rc ) { }

    function setupSubsystem( module ) { }

    function setupView( rc ) { }

}
