component accessors="true" {

  property name="Singleton" type="any";

  function init() {
    variables.greeting = "Hello";
    return this;
  }
  
  function sayHi(required string whom) {
    return variables.singleton.greet(whom);
  }
}
