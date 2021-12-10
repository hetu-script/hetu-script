import 'package:path/path.dart' as path;

import '../source/source.dart';
import '../error/error.dart';
import 'resource_context.dart';

typedef _RootUpdatedCallback = void Function();

/// Manage a set of resources.
/// A resource could be hetu source, yaml, json... etc.
/// Extends this class and provide an implementation of
/// [createContext] to manage a certain kind of [HTResourceContext]
abstract class HTResourceManager<T extends HTResourceContext> {
  bool get isSearchEnabled;

  final _contextRoots = <String, T>{};

  Iterable<T> get contexts => _contextRoots.values;

  final _cachedSources = <String, HTSource>{};

  Map<String, HTSource> get cachedSources => _cachedSources;

  /// Set up a callback for root updated event.
  _RootUpdatedCallback? onRootsUpdated;

  T createContext(String root);

  bool hasResource(String fullName) {
    // final normalized = HTResourceContext.getAbsolutePath(key: key);
    return _cachedSources.containsKey(fullName);
  }

  void addResource(String fullName, HTSource resource) {
    if (!path.isAbsolute(fullName)) {
      throw HTError.notAbsoluteError(fullName);
    }
    // final normalized = HTResourceContext.getAbsolutePath(key: fullName);
    for (final context in contexts) {
      if (context.contains(fullName)) {
        // final source = context.addResource(normalized, content);
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
    context.addResource(fullName, resource);
    _cachedSources[fullName] = resource;
    if (onRootsUpdated != null) {
      onRootsUpdated!();
    }
    // return source;
  }

  void removeResource(String fullName) {
    // final normalized = HTResourceContext.getAbsolutePath(key: fullName);
    for (final context in contexts) {
      if (context.contains(fullName)) {
        context.removeResource(fullName);
      }
    }
  }

  /// Try to get a source by a unique key.
  HTSource? getResource(String fullName, {bool reload = false}) {
    // final normalized = HTResourceContext.getAbsolutePath(key: fullName);
    if (_cachedSources.containsKey(fullName) && !reload) {
      return _cachedSources[fullName]!;
    } else if (isSearchEnabled) {
      for (final root in _contextRoots.keys) {
        if (path.isWithin(root, fullName)) {
          final context = _contextRoots[root]!;
          final source = context.getResource(fullName);
          return source;
        }
      }
    }
  }

  void updateResource(String fullName, String content) {
    // final normalized = HTResourceContext.getAbsolutePath(key: fullName);
    if (_cachedSources.containsKey(fullName)) {
      final source = _cachedSources[fullName]!;
      source.content = content;
    } else if (isSearchEnabled) {
      for (final root in _contextRoots.keys) {
        if (path.isWithin(root, fullName)) {
          final context = _contextRoots[root]!;
          context.updateResource(fullName, content);
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
