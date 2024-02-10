import 'dart:math' as math;

import 'package:path/path.dart' as path;

// import '../grammar/lexicon.dart';
import 'line_info.dart';
import '../resource/resource.dart';
import '../utils/crc32b.dart';
import '../common/internal_identifier.dart';

/// A piece of code, with extra informations like:
/// [fullName], [type], [lineInfo], etc.
class HTSource {
  static const _anonymousScriptNameLengthLimit = 18;

  String get basename => path.basename(fullName);

  late String fullName;

  HTResourceType type;

  String _content;
  String get content => _content;
  set content(String value) {
    _content = value;
    _lineInfo = LineInfo.fromContent(content);
  }

  LineInfo _lineInfo;
  LineInfo get lineInfo => _lineInfo;

  String? _crc;

  @override
  bool operator ==(Object other) =>
      other is HTSource ? hashCode == other.hashCode : false;

  @override
  int get hashCode => _crc != null ? _crc.hashCode : content.hashCode;

  HTSource(
    String content, {
    String? filename,
    this.type = HTResourceType.hetuModule,
    bool hashContent = false,
  })  : _content = content,
        _lineInfo = LineInfo.fromContent(content) {
    if (filename != null) {
      fullName = filename;
    } else {
      final hash = crcString(content);
      final nameBuilder = StringBuffer();
      nameBuilder.write('${InternalIdentifier.anonymousScript}_$hash: ');
      var firstLine =
          content.trimLeft().replaceAll(RegExp(r'\s+'), ' ').trimRight();
      nameBuilder.write(firstLine.substring(
          0, math.min(_anonymousScriptNameLengthLimit, firstLine.length)));
      if (firstLine.length > _anonymousScriptNameLengthLimit) {
        nameBuilder.write('...');
      }
      fullName = nameBuilder.toString();
    }

    if (hashContent) {
      _crc = crcString(content);
    }
  }
}

/// A value, however it can be imported like a source.
/// Typically a json file, which is a [HTStruct] value in Hetu Script.
class HTJsonSource {
  final String fullName;
  final String module;
  final dynamic value;

  const HTJsonSource(
      {required this.fullName, required this.module, required this.value});
}
