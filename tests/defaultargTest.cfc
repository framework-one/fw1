component extends="mxunit.framework.TestCase" {
	
    function checkDefaultInitArgWorks() {
		var factory = new framework.ioc( "/tests/model", { constants = { dsn = "sample" } } );
        var user37 = factory.getBean( "user37" );
        assertEquals( "sample", user37.getDSN() );
        assertEquals( 0, user37.getID() );

        var user37b = factory.getBean( "user37b" );
        assertEquals( "sample", user37b.getDSN() );
        assertEquals( 0, user37b.getID() );
    }

    function checkDefaultInitArgThreeArgs() {
        var factory = new framework.ioc( "/tests/model",
                               { constants = { dsn = "sample" } } );
        var user37c = factory.getBean( "user37c" );
        assertEquals( "sample", user37c.getDSN() );
        assertEquals( 0, user37c.getID() );
        assertEquals( "Bob", user37c.getName() );

        factory = new framework.ioc( "/tests/model",
                           { constants = { dsn = "sample", name = "John" } } );
        user37c = factory.getBean( "user37c" );
        assertEquals( "sample", user37c.getDSN() );
        assertEquals( 0, user37c.getID() );
        assertEquals( "John", user37c.getName() );

    }
	
    function checkDefaultInitArgWorksStrict() {
		var factory = new framework.ioc( "/tests/model",
                               { strict = true,
                                 constants = { dsn = "sample" } } );
        var user37 = factory.getBean( "user37" );
        assertEquals( "sample", user37.getDSN() );
        assertEquals( 0, user37.getID() );

        var user37b = factory.getBean( "user37b" );
        assertEquals( "sample", user37b.getDSN() );
        assertEquals( 0, user37b.getID() );
    }

    function checkDefaultInitArgThreeArgsStrict() {
        var factory = new framework.ioc( "/tests/model",
                               { strict = true,
                                 constants = { dsn = "sample" } } );
        var user37c = factory.getBean( "user37c" );
        assertEquals( "sample", user37c.getDSN() );
        assertEquals( 0, user37c.getID() );
        assertEquals( "Bob", user37c.getName() );

        factory = new framework.ioc( "/tests/model",
                           { strict = true,
                             constants = { dsn = "sample", name = "John" } } );
        user37c = factory.getBean( "user37c" );
        assertEquals( "sample", user37c.getDSN() );
        assertEquals( 0, user37c.getID() );
        assertEquals( "John", user37c.getName() );

    }

}
