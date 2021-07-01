import 'dart:math' as math;

import 'package:path/path.dart' as path;

import '../grammar/semantic.dart';
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
  static const _anonymousScriptSignatureLength = 72;

  late final String fullName;
  String get name => path.basename(fullName);

  final SourceType type;

  final bool isLibrary;

  late final String libraryName;

  String _content;
  String get content => _content;
  set content(String value) {
    _content = value;
    _lineInfo = LineInfo.fromContent(content);
  }

  LineInfo _lineInfo;
  LineInfo get lineInfo => _lineInfo;

  bool evaluated = false;

  HTSource(String content,
      {String? fullName,
      this.type = SourceType.module,
      this.isLibrary = false,
      String? libraryName})
      : _content = content,
        _lineInfo = LineInfo.fromContent(content) {
    if (fullName != null) {
      this.fullName = fullName;
    } else {
      final sigBuilder = StringBuffer();
      sigBuilder.write('${SemanticNames.anonymousScript}: {');
      var firstLine =
          content.trimLeft().replaceAll(RegExp(r'\s+'), ' ').trimRight();
      sigBuilder.write(firstLine.substring(
          0, math.min(_anonymousScriptSignatureLength, firstLine.length)));
      if (firstLine.length > _anonymousScriptSignatureLength) {
        sigBuilder.write('...');
      }
      sigBuilder.write('}');
      this.fullName = sigBuilder.toString();
    }
    this.libraryName = libraryName ?? this.fullName;
  }
}
