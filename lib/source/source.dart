import 'package:pub_semver/pub_semver.dart';

import '../core/const_table.dart';

/// Code module types
enum SourceType {
  /// A bare expression.
  expression,

  /// Module can only have declarations (variables, functions, classes, enums),
  /// import & export statement.
  module,

  /// Class can only have declarations (variables, functions).
  klass,

  /// Function & block can have declarations (variables, functions),
  /// expression & control statements.
  function,

  /// A script can have all statements.
  script,
}

class HTSource {
  final String fullName;

  String content;

  HTSource(this.fullName, this.content);
}
