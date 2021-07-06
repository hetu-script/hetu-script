import 'package:path/path.dart' as path;

import '../source/source.dart';
import 'context.dart';

/// Manage a set of contexts.
/// Extends this class and provide an implementation of
/// [createContext] to manage a certain kind of [HTContext]
abstract class HTContextManager<T extends HTContext> {
  bool get isSearchEnabled;

  final _contextRoots = <String, T>{};

  Iterable<T> get contexts => _contextRoots.values;

  final _cachedSources = <String, HTSource>{};

  Map<String, HTSource> get cachedSources => _cachedSources;

  Function? _rootsUpdatedCallback;

  T createContext(String root);

  bool hasSource(String key) {
    return _cachedSources.containsKey(key);
  }

  void addSource(String fullName, String content,
      {SourceType type = SourceType.module, bool isLibraryEntry = false}) {
    if (!path.isAbsolute(fullName)) {
      throw Exception('Adding source failed, not a absolute path: [$fullName]');
    }
    var isWithin = false;
    for (final context in contexts) {
      if (context.contains(fullName)) {
        final source = context.addSource(fullName, content,
            type: type, isLibraryEntry: isLibraryEntry);
        _cachedSources[source.fullName] = source;
        break;
      }
    }
    if (!isWithin) {
      final root = path.dirname(fullName);
      final context = createContext(root);
      _contextRoots[context.root] = context;
      final source = context.addSource(fullName, content,
          type: type, isLibraryEntry: isLibraryEntry);
      _cachedSources[source.fullName] = source;
    }
  }

  void removeSource(String fullName) {
    for (final context in contexts) {
      if (context.contains(fullName)) {
        context.removeSource(fullName);
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
    final roots = folderPaths.toSet();
    _comupteRoots(roots);
    _contextRoots.clear();
    for (final root in roots) {
      final context = createContext(root);
      _contextRoots[context.root] = context;
    }
    if (_rootsUpdatedCallback != null) {
      _rootsUpdatedCallback!();
    }
  }

  /// Computes roots from a set of files.
  ///
  /// The file paths does not neccessarily be normalized.
  void computeRootsFromFiles(Iterable<String> filePaths) {
    final roots = filePaths.map((filePath) => path.dirname(filePath)).toSet();
    setRoots(roots);
  }

  void _comupteRoots(Set<String> roots) {
    roots.removeWhere((root1) {
      for (final root2 in roots) {
        if (root2 == root1) continue;
        if (path.isWithin(root2, root1)) {
          return true;
        }
      }
      return false;
    });
  }

  /// Set up a callback for root updated event.
  void onRootsUpdated(Function callback) {
    _rootsUpdatedCallback = callback;
  }
}
