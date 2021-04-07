/// Function types
enum FunctionType {
  normal,
  method,
  constructor,
  getter,
  setter,
  literal, // function expression with no function name
  nested, // function within function, may with name
}

/// External function types
enum ExternalFunctionType {
  none,
  externalFunction,
  externalClassMethod,
}

enum FunctionReturnType {
  none, // void
  type, // HTTypeid
  superClassConstructor, // super class constructor
}

enum TypeType {
  normal, // HTTypeid
  function, // HTFunctionTypeid
  struct,
  union,
}

/// Class types
enum ClassType {
  normal,
  // nested,
  // abstracted,
  // interface,
  // mixIn,
  extern,
}

/// Code module types
enum CodeType {
  /// Expression can only have a single expression statement
  expression,

  /// Module can have declarations (variables, functions, classes, enums)
  /// and import & export statement
  module,

  /// Class can only have declarations (variables, functions)
  klass,

  /// Function & block can have declarations (variables, functions),
  /// expression & control statements.
  function,

  /// A script can have all statements.
  script,
}
