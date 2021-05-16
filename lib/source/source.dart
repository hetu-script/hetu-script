import 'package:path/path.dart' as path;
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

abstract class HTModule extends HTSource {
  Version? version;

  final Uri uri;

  bool evaluated = false;

  late final ConstTable constTable;

  String get name => path.basename(fullName);

  HTModule(String fullName, String content, [ConstTable? constTable])
      : uri = Uri(path: fullName),
        constTable = constTable ?? ConstTable(),
        super(fullName, content);
}

abstract class HTCompilation {
  Iterable<String> get keys;

  Iterable<HTModule> get sources;

  bool contains(String fullName);

  HTModule fetch(String fullName);
}
