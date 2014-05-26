component extends="framework.one" {

    function setupApplication() {
        setBeanFactory( new framework.ioc( "services" )  );
    }

}
