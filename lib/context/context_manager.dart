import 'package:path/path.dart' as path;

import '../source/source.dart';
import '../error/error.dart';
import 'context.dart';

typedef _RootUpdatedCallback = void Function();

/// Manage a set of contexts.
/// Extends this class and provide an implementation of
/// [createContext] to manage a certain kind of [HTContext]
abstract class HTContextManager<T extends HTContext> {
  bool get isSearchEnabled;

  final _contextRoots = <String, T>{};

  Iterable<T> get contexts => _contextRoots.values;

  final _cachedSources = <String, HTSource>{};

  Map<String, HTSource> get cachedSources => _cachedSources;

  /// Set up a callback for root updated event.
  _RootUpdatedCallback? onRootsUpdated;

  T createContext(String root);

  bool hasSource(String key) {
    return _cachedSources.containsKey(key);
  }

  HTSource addSource(String fullName, String content,
      {SourceType type = SourceType.module, bool isLibraryEntry = false}) {
    if (!path.isAbsolute(fullName)) {
      throw HTError.notAbsoluteError(fullName);
    }
    final normalized = HTContext.getAbsolutePath(key: fullName);
    // var isWithin = false;
    for (final context in contexts) {
      if (context.contains(normalized)) {
        final source = context.addSource(normalized, content,
            type: type, isLibraryEntry: isLibraryEntry);
        _cachedSources[normalized] = source;
        return source;
      }
    }
    // if (!isWithin) {
    final root = path.dirname(normalized);
    final context = createContext(root);
    _contextRoots[context.root] = context;
    final source = context.addSource(normalized, content,
        type: type, isLibraryEntry: isLibraryEntry);
    _cachedSources[normalized] = source;
    if (onRootsUpdated != null) {
      onRootsUpdated!();
    }
    return source;
    // }
  }

  void removeSource(String fullName) {
    final normalized = HTContext.getAbsolutePath(key: fullName);
    for (final context in contexts) {
      if (context.contains(normalized)) {
        context.removeSource(normalized);
      }
    }
  }

  /// Try to get a source by a unique key.
  HTSource? getSource(String fullName, {bool reload = false}) {
    final normalized = HTContext.getAbsolutePath(key: fullName);
    if (_cachedSources.containsKey(normalized) && !reload) {
      return _cachedSources[normalized]!;
    } else if (isSearchEnabled) {
      for (final root in _contextRoots.keys) {
        if (path.isWithin(root, normalized)) {
          final context = _contextRoots[root]!;
          final source = context.getSource(normalized);
          return source;
        }
      }
    }
  }

  void updateSource(String fullName, String content) {
    final normalized = HTContext.getAbsolutePath(key: fullName);
    if (_cachedSources.containsKey(normalized)) {
      final source = _cachedSources[normalized]!;
      source.content = content;
    } else if (isSearchEnabled) {
      for (final root in _contextRoots.keys) {
        if (path.isWithin(root, normalized)) {
          final context = _contextRoots[root]!;
          context.updateSource(normalized, content);
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
        .map((folderPath) => HTContext.getAbsolutePath(key: folderPath))
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
        .map((folderPath) =>
            path.dirname(HTContext.getAbsolutePath(key: folderPath)))
        .toSet();
    setRoots(roots);
  }

  // void onRootsUpdated(Function callback) {
  //   _rootsUpdatedCallback = callback;
  // }
}
