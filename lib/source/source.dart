import 'dart:math' as math;

import 'package:path/path.dart' as path;

// import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../util/crc32b.dart';
import 'line_info.dart';

const hetuSouceFileExtension = '.ht';

/// Code module types
enum SourceType {
  /// An expression.
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

  /// Literal struct definition (declarations).
  struct,
}

class HTSource {
  static const _anonymousScriptSignatureLength = 72;

  late final String fullName;
  String get name => path.basename(fullName);

  final SourceType type;

  String _content;
  String get content => _content;
  set content(String value) {
    _content = value;
    _lineInfo = LineInfo.fromContent(content);
  }

  LineInfo _lineInfo;
  LineInfo get lineInfo => _lineInfo;

  final bool isLibraryEntry;

  HTSource(String content,
      {String? fullName,
      this.type = SourceType.module,
      this.isLibraryEntry = false})
      : _content = content,
        _lineInfo = LineInfo.fromContent(content) {
    if (fullName != null) {
      this.fullName = fullName;
    } else {
      final crc32b = Crc32b.compute(content);
      final sigBuilder = StringBuffer();
      sigBuilder.write('${SemanticNames.anonymousScript}_$crc32b: ');
      var firstLine =
          content.trimLeft().replaceAll(RegExp(r'\s+'), ' ').trimRight();
      sigBuilder.write(firstLine.substring(
          0, math.min(_anonymousScriptSignatureLength, firstLine.length)));
      if (firstLine.length > _anonymousScriptSignatureLength) {
        sigBuilder.write('...');
      }
      this.fullName = sigBuilder.toString();
    }

    // if (type == SourceType.module) {
    //   final pattern = RegExp(
    //     HTLexicon.libraryNamePattern,
    //     unicode: true,
    //   );
    //   final matches = pattern.allMatches(content);
    //   if (matches.isNotEmpty) {
    //     final singleMark = matches.first.group(HTLexicon.libraryNameSingleMark);
    //     if (singleMark != null) {
    //       _isLibrary = true;
    //       libraryName ??= singleMark;
    //     } else {
    //       final doubleMark =
    //           matches.first.group(HTLexicon.libraryNameDoubleMark);
    //       if (doubleMark != null) {
    //         _isLibrary = true;
    //         libraryName ??= doubleMark;
    //       }
    //     }
    //   }
    // }

    // this.libraryName = libraryName ?? this.fullName;
  }
}
