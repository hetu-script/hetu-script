import 'package:hetu_script/context/context_manager.dart';
import 'package:path/path.dart' as path;

import '../../source/source.dart';
import 'file_system_context.dart';
import '../context.dart';

class HTFileSystemContextManager implements HTContextManager {
  final _contextRoots = <String, HTFileSystemContext>{};

  @override
  Iterable<HTContext> get contexts => _contextRoots.values;

  final _cachedSources = <String, HTSource>{};

  Function? _rootsUpdatedCallback;

  @override
  bool hasSource(String key) => _cachedSources.containsKey(key);

  @override
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
      final context = HTFileSystemContext(root: root, cache: _cachedSources);
      _contextRoots[root] = context;
      final source = context.addSource(fullName, content,
          type: type, isLibraryEntry: isLibraryEntry);
      _cachedSources[source.fullName] = source;
    }
  }

  @override
  HTSource getSource(String fullName, {bool reload = false}) {
    if (_cachedSources.containsKey(fullName) && !reload) {
      return _cachedSources[fullName]!;
    } else {
      String? parent;
      for (final root in _contextRoots.keys) {
        if (path.isWithin(root, fullName)) {
          parent = root;
          break;
        }
      }
      if (parent != null) {
        final source = _contextRoots[parent]!.getSource(fullName);
        return source;
      } else {
        throw Exception('Could not find source: [$fullName]');
      }
    }
  }

  @override
  void setRoots(Iterable<String> folderPaths) {
    _contextRoots.clear();
    final roots = folderPaths.toSet();
    _comupteRoots(roots);
    for (final folder in roots) {
      final context = HTFileSystemContext(root: folder, cache: _cachedSources);
      _contextRoots[folder] = context;
    }
    if (_rootsUpdatedCallback != null) {
      _rootsUpdatedCallback!();
    }
  }

  @override
  void setRootsFromFiles(Iterable<String> filePaths) {
    _contextRoots.clear();
    final roots = filePaths.toSet();
    _comupteRoots(roots);
    for (final root in roots) {
      final context = HTFileSystemContext(root: root, cache: _cachedSources);
      _contextRoots[root] = context;
    }
    if (_rootsUpdatedCallback != null) {
      _rootsUpdatedCallback!();
    }
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

  @override
  void onRootsUpdated(Function callback) {
    _rootsUpdatedCallback = callback;
  }
}
