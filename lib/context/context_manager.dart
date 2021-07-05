import 'package:path/path.dart' as path;

import '../source/source.dart';
import '../context/context.dart';

class HTContextManager {
  final contextRoots = <String, HTContext>{};

  final cachedSources = <String, HTSource>{};

  bool hasSource(String key) => cachedSources.containsKey(key);

  HTSource getSource(String fullName, {bool reload = false}) {
    if (cachedSources.containsKey(fullName) && !reload) {
      return cachedSources[fullName]!;
    } else {
      String? parent;
      for (final root in contextRoots.keys) {
        if (path.isWithin(root, fullName)) {
          parent = root;
          break;
        }
      }
      if (parent != null) {
        final source = contextRoots[parent]!.getSource(fullName);
        return source;
      } else {
        throw Exception('Could not find source: [$fullName]');
      }
    }
  }

  /// Create context for a set of folders.
  ///
  /// The folder paths should be absolute and normalized.
  void setRoots(Iterable<String> folderPaths) {
    contextRoots.clear();
    final roots = folderPaths.toSet();
    _comupteRoots(roots);
    for (final folder in roots) {
      final context = HTContext(rootPath: folder, cache: cachedSources);
      contextRoots[folder] = context;
    }
    afterRootsUpdated();
  }

  /// Computes analysis roots for a set of files.
  ///
  /// The file paths should be absolute and normalized.
  void setRootsFromFiles(Iterable<String> filePaths) {
    contextRoots.clear();
    final roots = <String>{};
    for (final fileName in filePaths) {
      roots.add(fileName);
    }
    _comupteRoots(roots);
    for (final root in roots) {
      final context = HTContext(rootPath: root, cache: cachedSources);
      contextRoots[root] = context;
    }
    afterRootsUpdated();
  }

  void _comupteRoots(Set<String> roots) {
    roots.removeWhere((item) {
      for (final root in roots) {
        if (root == item) continue;
        if (path.isWithin(root, item)) {
          return true;
        }
      }
      return false;
    });
  }

  void afterRootsUpdated() {}
}
