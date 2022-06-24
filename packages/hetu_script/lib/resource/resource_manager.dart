import 'package:path/path.dart' as path;

import '../error/error.dart';
import 'resource_context.dart';

typedef RootUpdatedCallback = void Function();

/// Manage a set of resources.
/// A resource could be hetu source, yaml, json... etc.
/// Extends this class and provide an implementation of
/// [createContext] to manage a certain kind of [HTResourceContext]
abstract class HTSourceManager<RT, CT extends HTResourceContext<RT>> {
  bool get isSearchEnabled;

  final _contextRoots = <String, CT>{};

  Iterable<CT> get contexts => _contextRoots.values;

  final _cachedSources = <String, RT>{};

  Map<String, RT> get cachedSources => _cachedSources;

  /// Set up a callback for root updated event.
  RootUpdatedCallback? onRootsUpdated;

  CT createContext(String root);

  bool hasResource(String fullName) {
    // final normalized = HTResourceContext.getAbsolutePath(key: key);
    return _cachedSources.containsKey(fullName);
  }

  void addResource(String fullName, RT resource) {
    if (!path.isAbsolute(fullName)) {
      throw HTError.notAbsoluteError(fullName);
    }
    for (final context in contexts) {
      final normalized = context.getAbsolutePath(key: fullName);
      if (context.contains(normalized)) {
        _cachedSources[fullName] = resource;
        if (onRootsUpdated != null) {
          onRootsUpdated!();
        }
        return;
      }
    }
    final root = path.dirname(fullName);
    final context = createContext(root);
    _contextRoots[context.root] = context;
    final normalized = context.getAbsolutePath(key: fullName);
    context.addResource(normalized, resource);
    _cachedSources[fullName] = resource;
    if (onRootsUpdated != null) {
      onRootsUpdated!();
    }
  }

  void removeResource(String fullName) {
    for (final context in contexts) {
      final normalized = context.getAbsolutePath(key: fullName);
      if (context.contains(normalized)) {
        context.removeResource(normalized);
      }
      return;
    }
  }

  /// Try to get a source by a unique key.
  RT? getResource(String fullName, {bool reload = false}) {
    if (_cachedSources.containsKey(fullName) && !reload) {
      return _cachedSources[fullName]!;
    } else if (isSearchEnabled) {
      for (final root in _contextRoots.keys) {
        if (path.isWithin(root, fullName)) {
          final context = _contextRoots[root]!;
          final normalized = context.getAbsolutePath(key: fullName);
          final source = context.getResource(normalized);
          return source;
        }
      }
    }
    return null;
  }

  void updateResource(String fullName, RT resource) {
    if (_cachedSources.containsKey(fullName)) {
      _cachedSources[fullName] = resource;
    } else if (isSearchEnabled) {
      for (final root in _contextRoots.keys) {
        if (path.isWithin(root, fullName)) {
          final context = _contextRoots[root]!;
          final normalized = context.getAbsolutePath(key: fullName);
          context.updateResource(normalized, resource);
          break;
        }
      }
    }
  }

  /// Create context from a set of folders.
  ///
  /// The folder paths does not neccessarily be normalized.
  void setRoots(Iterable<String> folderPaths) {
    final roots = folderPaths
        // .map((folderPath) => HTResourceContext.getAbsolutePath(key: folderPath))
        .toSet();
    roots.removeWhere((root1) {
      for (final root2 in roots) {
        if (root2 == root1) continue;
        if (path.isWithin(root2, root1)) {
          return true;
        }
      }
      return false;
    });
    _contextRoots.clear();
    for (final root in roots) {
      final context = createContext(root);
      _contextRoots[root] = context;
    }
    if (onRootsUpdated != null) {
      onRootsUpdated!();
    }
  }

  /// Computes roots from a set of files.
  ///
  /// The file paths does not neccessarily be normalized.
  void computeRootsFromFiles(Iterable<String> filePaths) {
    final roots = filePaths
        // .map((folderPath) =>
        // path.dirname(HTResourceContext.getAbsolutePath(key: folderPath)))
        .toSet();
    setRoots(roots);
  }

  // void onRootsUpdated(Function callback) {
  //   _rootsUpdatedCallback = callback;
  // }
}
