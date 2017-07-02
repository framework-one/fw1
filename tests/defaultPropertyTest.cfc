component extends=mxunit.framework.TestCase {

    function setup() {
        variables.bf = new framework.ioc( "" )
            .declare( "default" ).instanceOf( "tests.extrabeans.sheep.default" )
            .asTransient()
            .done();
    }

    function testHaveDefaultValue() {
        var data = {
            viaNew : new tests.extrabeans.sheep.default(),
            viaDI1 : variables.bf.getBean( "default" )
        };
        assertTrue( isNull( data.viaNew.getSimple() ) );
        assertTrue( isNull( data.viaNew.getTyped() ) );
        assertEquals( "Default Value", data.viaNew.getDefaulted() );
        assertEquals( "Default Type Value", data.viaNew.getDefaultedType() );
        assertTrue( isNull( data.viaDI1.getSimple() ) );
        assertTrue( isNull( data.viaDI1.getTyped() ) );
        assertEquals( "Default Value", data.viaDI1.getDefaulted() );
        assertEquals( "Default Type Value", data.viaDI1.getDefaultedType() );
    }

}
