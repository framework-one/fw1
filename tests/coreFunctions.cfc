component extends=testbox.system.BaseSpec {

  function beforeAll() {
    variables.fw = new framework.one();
    variables.fw.__config = __config;
  }

  function afterAll() {
  }

  function run( testResults, testBox ) {

    describe( "getDefaultSubsystem", function(){
      beforeEach(function(){
        structDelete( request, "subsystem" );
        structDelete( request, "section" );
        structAppend( variables.fw.__config(), {
          usingSubsystems : false,
          subsystemDelimiter : "@",
          defaultSubsystem : "",
          defaultSection : "section",
          defaultItem : "item"
        });
      });
      it( "should return empty string without subsystems", function(){
        expect( fw.getDefaultSubsystem() ).toBeEmpty();
      });
      it( "should return request subsystem, if present", function(){
        fw.__config().usingSubsystems = true;
        request.subsystem = "requested";
        expect( fw.getDefaultSubsystem() ).toBe( "requested" );
      });
      it( "should return default subsystem, if request not present", function(){
        fw.__config().usingSubsystems = true;
        fw.__config().defaultSubsystem = "subsystem";
        expect( fw.getDefaultSubsystem() ).toBe( "subsystem" );
      });
      it( "should throw an exception, if no default", function(){
        fw.__config().usingSubsystems = true;
        expect(function(){
          return fw.getDefaultSubsystem();
        }).toThrow( type = "FW1.subsystemNotSpecified" );
      });
    });

  }

  function __config() {
    return variables.framework;
  }

}
