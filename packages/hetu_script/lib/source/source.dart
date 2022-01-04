import 'dart:math' as math;

import 'package:path/path.dart' as path;

// import '../grammar/lexicon.dart';
import '../grammar/semantic.dart';
import '../shared/crc32b.dart';
import 'line_info.dart';
import '../resource/resource.dart';

class HTSource {
  static const _anonymousScriptNameLengthLimit = 18;

  String get basename => path.basename(_fullName);

  late final String _fullName;

  String get fullName => _fullName;

  ResourceType type;

  String _content;
  String get content => _content;
  set content(String value) {
    _content = value;
    _lineInfo = LineInfo.fromContent(content);
  }

  LineInfo _lineInfo;
  LineInfo get lineInfo => _lineInfo;

  HTSource(
    String content, {
    String? fullName,
    this.type = ResourceType.hetuModule,
  })  : _content = content,
        _lineInfo = LineInfo.fromContent(content) {
    if (fullName != null) {
      _fullName = fullName;
    } else {
      final crc32b = Crc32b.compute(content);
      final nameBuilder = StringBuffer();
      nameBuilder.write('${Semantic.anonymousScript}_$crc32b: ');
      var firstLine =
          content.trimLeft().replaceAll(RegExp(r'\s+'), ' ').trimRight();
      nameBuilder.write(firstLine.substring(
          0, math.min(_anonymousScriptNameLengthLimit, firstLine.length)));
      if (firstLine.length > _anonymousScriptNameLengthLimit) {
        nameBuilder.write('...');
      }
      _fullName = nameBuilder.toString();
    }
  }
}

class HTValueSource {
  final String id;
  final String moduleName;
  final dynamic value;

  const HTValueSource(
      {required this.id, required this.moduleName, required this.value});
}
