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
    return _cached.containsKey(key);
  }

  @override
  void addResource(String fullName, HTSource resource) {
    resource.fullName = fullName;
    _cached[fullName] = resource;
    included.add(resource.fullName);
  }

  @override
  void removeResource(String fullName) {
    _cached.remove(fullName);
    included.remove(fullName);
  }

  @override
  HTSource getResource(String key, {String? from}) {
    if (_cached.containsKey(key)) {
      return _cached[key]!;
    }
    throw HTError.resourceDoesNotExist(key);
  }

  @override
  void updateResource(String fullName, HTSource resource) {
    if (_cached.containsKey(fullName)) {
      // final source = _cached[normalized]!;
      // source.content = resource;
      resource.fullName = fullName;
      _cached[fullName] = resource;
      return;
    }
    throw HTError.resourceDoesNotExist(fullName);
  }
}
