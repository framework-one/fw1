component {

  this.mappings[ '/framework' ] = expandPath( '../../framework' );
  this.mappings[ '/beans' ] = expandPath( './beans' );

  function onRequestStart() {
    if (structKeyExists(url, "reinit")) {
      structDelete(application, "beanFactory");
    }
    if (!structKeyExists(application, "beanFactory")) {
      lock scope="application" timeout="5" {
        var bf = new framework.ioc(folders=[]);
        bf.declare("Greeting").asValue("Hello");
        // this singleton has a constructor dependancy on Greeting
        bf.declare("Singleton").instanceOf("beans.Singleton").asSingleton();
        // this transient has a setter dependancy on Singleton
        bf.declare("Transient").instanceOf("beans.Transient").asTransient();
        application.beanFactory = bf;
      }
    }
  }

  function onError(Exception, eventName) {
    if (structKeyExists(Exception, "message")) {
      writeOutput(Exception.message);
    }
    writeDump(var=Exception, format="text");
  }

}
