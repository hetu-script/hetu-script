import 'package:path/path.dart' as path;

import 'line_info.dart';

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

  final SourceType type;

  final bool isLibrary;

  final String libraryName;

  String _content;
  String get content => _content;
  set content(String value) {
    _content = value;
    _lineInfo = LineInfo.fromContent(content);
  }

  LineInfo _lineInfo;
  LineInfo get lineInfo => _lineInfo;

  bool evaluated = false;

  HTSource(this.fullName, String content,
      {this.type = SourceType.module,
      this.isLibrary = false,
      String? libraryName})
      : libraryName = libraryName ?? fullName,
        _content = content,
        _lineInfo = LineInfo.fromContent(content);
}
