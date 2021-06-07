import 'package:path/path.dart' as path;

/// Code module types
enum SourceType {
  /// A bare expression.
  expression,

  /// Module can only have declarations (variables, functions, classes, enums),
  /// import & export statement.
  module,

  /// Function & block can have declarations (variables, functions),
  /// expression & control statements.
  function,

  /// A script can have all statements.
  script,

  /// Class can only have declarations (variables, functions).
  klass,

  /// Literal struct definition (fields).
  struct,
}

class HTSource {
  final String fullName;

  String get name => path.basename(fullName);

  String content;

  HTSource(this.fullName, this.content);
}
