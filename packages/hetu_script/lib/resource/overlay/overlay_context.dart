import 'package:path/path.dart' as path;

import '../../error/error.dart';
import '../../source/source.dart';
import '../resource_context.dart';

/// [HTOverlayContext] are a virtual set of files that
/// not neccessarily exists as physical files.
///
/// [HTOverlayContext] will not scan physical disk,
/// instead it depends on [addResource] method
/// to manage sources
class HTOverlayContext extends HTResourceContext<HTSource> {
  @override
  late final String root;

  @override
  final Set<String> included = <String>{};

  final Map<String, HTSource> _cached;

  HTOverlayContext({String? root, Map<String, HTSource>? cache})
      : _cached = cache ?? <String, HTSource>{} {
    root = root != null ? path.absolute(root) : path.current;
    this.root = getAbsolutePath(dirName: root);
  }

  @override
  bool contains(String key) {
    final normalized = getAbsolutePath(key: key, dirName: root);
    return path.isWithin(root, normalized);
  }

  @override
  void addResource(String fullName, HTSource resource) {
    final normalized = getAbsolutePath(key: fullName, dirName: root);
    resource.name = normalized;
    _cached[normalized] = resource;
    included.add(normalized);
    // return source;
  }

  @override
  void removeResource(String fullName) {
    final normalized = getAbsolutePath(key: fullName, dirName: root);
    _cached.remove(normalized);
    included.remove(normalized);
  }

  @override
  HTSource getResource(String key, {String? from}) {
    final normalized = getAbsolutePath(
        key: key, dirName: from != null ? path.dirname(from) : root);
    if (_cached.containsKey(normalized)) {
      return _cached[normalized]!;
    }
    throw HTError.sourceProviderError(normalized);
  }

  @override
  void updateResource(String fullName, HTSource resource) {
    final normalized = getAbsolutePath(key: fullName, dirName: root);
    if (_cached.containsKey(normalized)) {
      // final source = _cached[normalized]!;
      // source.content = resource;
      _cached[normalized] = resource;
      return;
    }
    throw HTError.sourceProviderError(fullName);
  }
}
