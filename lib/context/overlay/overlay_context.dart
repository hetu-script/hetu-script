import 'package:path/path.dart' as path;

import '../../error/error.dart';
import '../../source/source.dart';
import '../context.dart';

/// [HTOverlayContext] are a virtual set of files that
/// not neccessarily exists as physical files.
///
/// [HTOverlayContext] will not scan physical disk,
/// instead it depends on [addSource] method
/// to manage sources
class HTOverlayContext implements HTContext {
  @override
  late final String root;

  @override
  Iterable<String> get included => _cached.keys;

  final Map<String, HTSource> _cached;

  HTOverlayContext({String? root, Map<String, HTSource>? cache})
      : _cached = cache ?? <String, HTSource>{} {
    root = root != null ? path.absolute(root) : path.current;
    this.root = HTContext.getAbsolutePath(dirName: root);
  }

  @override
  bool contains(String fullName) {
    final normalized = HTContext.getAbsolutePath(key: fullName, dirName: root);
    return path.isWithin(root, normalized);
  }

  @override
  HTSource addSource(String fullName, String content,
      {SourceType type = SourceType.module, bool isLibraryEntry = false}) {
    final normalized = HTContext.getAbsolutePath(key: fullName, dirName: root);
    final source = HTSource(content,
        fullName: normalized, type: type, isLibraryEntry: isLibraryEntry);
    _cached[normalized] = source;
    return source;
  }

  @override
  void removeSource(String fullName) {
    final normalized = HTContext.getAbsolutePath(key: fullName, dirName: root);
    _cached.remove(normalized);
  }

  @override
  HTSource getSource(String key,
      {String? from,
      SourceType type = SourceType.module,
      bool isLibraryEntry = false}) {
    final normalized = HTContext.getAbsolutePath(
        key: key, dirName: from != null ? path.dirname(from) : root);
    if (_cached.containsKey(normalized)) {
      return _cached[normalized]!;
    }
    throw HTError.sourceProviderError(normalized);
  }

  @override
  void updateSource(String fullName, String content) {
    final normalized = HTContext.getAbsolutePath(key: fullName, dirName: root);
    if (_cached.containsKey(normalized)) {
      final source = _cached[normalized]!;
      source.content = content;
      return;
    }
    throw HTError.sourceProviderError(fullName);
  }
}
