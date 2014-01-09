component extends="org.corfield.framework" {

    function setupApplication() {
        var bf = new framework.WireBoxAdapter();
        bf.getBinder().scanLocations( "examples.wirebox.model" );
        setBeanFactory( bf );
    }

}
