component extends="org.corfield.framework" {

    function setupApplication() {
        setBeanFactory( new framework.ioc( "services" ) );
    }

}
