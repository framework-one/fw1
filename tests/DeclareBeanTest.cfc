component extends="mxunit.framework.TestCase" {

    function shouldDeclareSingleton() {
        var bf = new framework.ioc( "" ).declareBean( "foo", "tests.extrabeans.sheep.item" );
        structDelete( application, "itemCount" );
        var item1 = bf.getBean( "foo" );
        assertEquals( 1, application.itemCount );
        var item2 = bf.getBean( "foo" );
        assertEquals( 1, application.itemCount );
        assertSame( item1, item2 );
    }

    function shouldDeclareTransient() {
        var bf = new framework.ioc( "" ).declareBean( "foo", "tests.extrabeans.sheep.item", false );
        structDelete( application, "itemCount" );
        var item1 = bf.getBean( "foo" );
        assertEquals( 1, application.itemCount );
        var item2 = bf.getBean( "foo" );
        assertEquals( 2, application.itemCount );
        assertNotSame( item1, item2 );
    }

    function shouldDeclareSingletonWithOverride() {
        var bf = new framework.ioc( "" ).declareBean( "foo", "tests.extrabeans.sheep.item", true, { start = 100 } );
        structDelete( application, "itemCount" );
        var item1 = bf.getBean( "foo" );
        assertEquals( 101, application.itemCount );
        var item2 = bf.getBean( "foo" );
        assertEquals( 101, application.itemCount );
        assertSame( item1, item2 );
    }

    function shouldDeclareTransientWithOverride() {
        var bf = new framework.ioc( "" ).declareBean( "foo", "tests.extrabeans.sheep.item", false, { start = 100 } );
        structDelete( application, "itemCount" );
        var item1 = bf.getBean( "foo" );
        assertEquals( 101, application.itemCount );
        var item2 = bf.getBean( "foo" );
        assertEquals( 102, application.itemCount );
        assertNotSame( item1, item2 );
    }

    function shouldDeclareAndAdd() {
        var bf = new framework.ioc( "" ).declareBean( "foo", "tests.declared.things.myconfig" ).addBean( "name", "test" ).addBean( "config", "some" );
        var item = bf.getBean( "foo" );
        assertEquals( "test", item.getName() );
        assertEquals( "some", item.getConfig() );
    }

    function shouldDeclareWithOverride() {
        var bf = new framework.ioc( "" ).declareBean( "foo", "tests.declared.things.myconfig", true, { name = "test", config = "some" } )
            .addBean( "name", "not-test" ).addBean( "config", "config" );
        var item = bf.getBean( "foo" );
        assertEquals( "test", item.getName() );
        assertEquals( "some", item.getConfig() );
    }

}
