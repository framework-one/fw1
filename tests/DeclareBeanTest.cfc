component extends="mxunit.framework.TestCase" {

    function shouldDeclareSingleton() {
        var bf = new framework.ioc( "" )
            .declare( "foo" ).instanceOf( "tests.extrabeans.sheep.item" ).done();
        structDelete( application, "itemCount" );
        var item1 = bf.getBean( "foo" );
        assertEquals( 1, application.itemCount );
        var item2 = bf.getBean( "foo" );
        assertEquals( 1, application.itemCount );
        assertSame( item1, item2 );
    }

    function shouldDeclareTransient() {
        var bf = new framework.ioc( "" )
            .declare( "foo" )
            .instanceOf( "tests.extrabeans.sheep.item" )
            .asTransient()
            .done();
        structDelete( application, "itemCount" );
        var item1 = bf.getBean( "foo" );
        assertEquals( 1, application.itemCount );
        var item2 = bf.getBean( "foo" );
        assertEquals( 2, application.itemCount );
        assertNotSame( item1, item2 );
    }

    function shouldDeclareSingletonWithOverride() {
        var bf = new framework.ioc( "" )
            .declare( "foo" )
            .instanceOf( "tests.extrabeans.sheep.item" )
            .withOverrides( { start = 100 } )
            .done();
        structDelete( application, "itemCount" );
        var item1 = bf.getBean( "foo" );
        assertEquals( 101, application.itemCount );
        var item2 = bf.getBean( "foo" );
        assertEquals( 101, application.itemCount );
        assertSame( item1, item2 );
    }

    function shouldDeclareTransientWithOverride() {
        var bf = new framework.ioc( "" )
            .declare( "foo" )
            .instanceOf( "tests.extrabeans.sheep.item" )
            .asTransient()
            .withOverrides( { start = 100 } )
            .done();
        structDelete( application, "itemCount" );
        var item1 = bf.getBean( "foo" );
        assertEquals( 101, application.itemCount );
        var item2 = bf.getBean( "foo" );
        assertEquals( 102, application.itemCount );
        assertNotSame( item1, item2 );
    }

    function shouldDeclareAndAdd() {
        var bf = new framework.ioc( "", { omitTypedProperties = false } )
            .declare( "foo" ).instanceOf( "tests.declared.things.myconfig" ).done()
            .declare( "name" ).asValue( "test" ).done()
            .declare( "config" ).asValue( "some" ).done();
        var item = bf.getBean( "foo" );
        assertEquals( "test", item.getName() );
        assertEquals( "some", item.getConfig() );
    }

    function shouldDeclareWithOverride() {
        var bf = new framework.ioc( "", { omitTypedProperties = false } )
            .declare( "foo" )
            .instanceOf( "tests.declared.things.myconfig" )
            .withOverrides( { name = "test", config = "some" } ).done()
            .addBean( "name", "not-test" ).addBean( "config", "config" );
        var item = bf.getBean( "foo" );
        assertEquals( "test", item.getName() );
        assertEquals( "some", item.getConfig() );
    }

    function shouldDeclareInteractWithDefault() {
        var bf = new framework.ioc( "", { omitDefaultedProperties = false } ).declareBean( "foo", "tests.declared.things.myconfig" )
            .addBean( "dftname", "injected" );
        var item = bf.getBean( "foo" );
        assertEquals( "injected", item.getDftName() );
        var bf = new framework.ioc( "", { omitDefaultedProperties = true } ).declareBean( "foo", "tests.declared.things.myconfig" )
            .addBean( "dftname", "injected" );
        var item = bf.getBean( "foo" );
        assertEquals( "default", item.getDftName() );
    }

}
