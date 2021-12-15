import 'dart:io';

import 'package:hetu_script/source/source.dart';
import 'package:path/path.dart' as path;

import 'package:hetu_script/hetu_script.dart';

/// [HTResourceContext] are a set of files and folders under a folder or a path.
class HTFileSystemSourceContext extends HTResourceContext<HTSource> {
  @override
  late final String root;

  @override
  final Set<String> included = <String>{};

  final Map<String, HTSource> _cached;

  @override
  String getAbsolutePath({String key = '', String? dirName, String? fileName}) {
    final normalized =
        super.getAbsolutePath(key: key, dirName: dirName, fileName: fileName);
    if (Platform.isWindows && normalized.startsWith('/')) {
      return normalized.substring(1);
    } else {
      return normalized;
    }
  }

  HTFileSystemSourceContext(
      {String? root,
      List<HTFilterConfig> includedFilter = const [],
      List<HTFilterConfig> excludedFilter = const [],
      Map<String, HTSource>? cache,
      List<String> expressionModuleExtensions = const [],
      List<String> binaryModuleExtensions = const []})
      : _cached = cache ?? <String, HTSource>{},
        super(
            expressionModuleExtensions: expressionModuleExtensions,
            binaryModuleExtensions: binaryModuleExtensions) {
    root = root != null ? path.absolute(root) : path.current;
    this.root = root = getAbsolutePath(dirName: root);
    final dir = Directory(root);
    final folderFilter = HTFilterConfig(root);
    final entities = dir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File) {
        final fileFullName = getAbsolutePath(key: entity.path, dirName: root);
        var isIncluded = false;
        if (includedFilter.isEmpty) {
          isIncluded = _filterFile(fileFullName, folderFilter);
        } else {
          for (final filter in includedFilter) {
            if (_filterFile(fileFullName, filter)) {
              isIncluded = true;
              break;
            }
          }
        }
        if (isIncluded) {
          if (excludedFilter.isNotEmpty) {
            for (final filter in excludedFilter) {
              final isExcluded = _filterFile(fileFullName, filter);
              if (isExcluded) {
                isIncluded = false;
                break;
              }
            }
          }
        }
        if (isIncluded) {
          included.add(fileFullName);
        }
      }
    }
  }

  @override
  bool contains(String key) {
    final normalized = getAbsolutePath(key: key, dirName: root);
    return path.isWithin(root, normalized);
  }

  @override
  void addResource(String fullName, HTSource resource) {
    resource.name = fullName;
    _cached[fullName] = resource;
    included.add(fullName);
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
    } else {
      final content = File(normalized).readAsStringSync();
      final ext = path.extension(normalized);
      final source =
          HTSource(content, name: normalized, type: checkExtension(ext));
      addResource(normalized, source);
      return source;
    }
  }

  @override
  void updateResource(String fullName, HTSource resource) {
    final normalized = getAbsolutePath(key: fullName);
    if (!_cached.containsKey(normalized)) {
      throw HTError.sourceProviderError(normalized);
    } else {
      _cached[normalized] = resource;
    }
  }

  // [fullPath] must be a normalized absolute path
  bool _filterFile(String fileName, HTFilterConfig filter) {
    final ext = path.extension(fileName);
    final normalizedFilePath = getAbsolutePath(key: fileName, dirName: root);
    final normalizedFolderPath =
        getAbsolutePath(key: filter.folder, dirName: root);
    if (path.isWithin(normalizedFolderPath, normalizedFilePath)) {
      if (filter.recursive) {
        return _checkExt(ext, filter.extension);
      } else {
        final fileDirName = path.basename(path.dirname(fileName));
        final folderDirName = path.basename(normalizedFolderPath);
        if (fileDirName == folderDirName) {
          return _checkExt(ext, filter.extension);
        }
      }
    }
    return false;
  }

  bool _checkExt(String ext, List<String> extList) {
    if (extList.isEmpty) {
      return true;
    } else {
      for (final includedExt in extList) {
        if (ext == includedExt) {
          return true;
        }
      }
      return false;
    }
  }
}
