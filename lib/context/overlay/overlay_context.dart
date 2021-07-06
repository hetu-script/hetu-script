import 'dart:io';

import 'package:path/path.dart' as path;

import '../../error/error.dart';
import '../../source/source.dart';
import '../context.dart';

/// [HTOverlayContext] are a virtual set of files that
/// not neccessarily exists as physical files.
class HTOverlayContext implements HTContext {
  @override
  late final String root;

  @override
  final included = <String>[];

  final Map<String, HTSource> _cached;

  HTOverlayContext({String? root}) : _cached = <String, HTSource>{};

  @override
  bool contains(String fullName) {
    return path.isWithin(root, fullName);
  }

  @override
  HTSource addSource(String fullName, String content,
      {SourceType type = SourceType.module, bool isLibraryEntry = false}) {}

  @override
  HTSource getSource(String key,
      {String? from,
      SourceType type = SourceType.module,
      bool isLibraryEntry = false}) {
    final fullName = HTContext.getAbsolutePath(
        key: key, dirName: from != null ? path.dirname(from) : root);
  }

  @override
  void updateSource(String fullName, String content) {
    if (!_cached.containsKey(fullName)) {
      throw HTError.souceProviderError(
          fullName, 'Context error: could not load file with path');
    } else {
      final source = _cached[fullName]!;
      source.content = content;
    }
  }
}
