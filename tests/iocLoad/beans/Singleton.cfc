component {
  function init(greeting) {
    variables.greeting = greeting;
    return this;
  }
  function greet(required string whom) {
    return variables.greeting & " " & whom;
  }
}
