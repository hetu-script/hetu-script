import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:hetu_script/hetu_script.dart';

/// [HTResourceContext] are a set of files and folders under a folder or a path.
class HTFileSystemSourceContext implements HTResourceContext<HTSource> {
  @override
  late final String root;

  @override
  final Set<String> included = <String>{};

  final Map<String, HTSource> _cached;

  final isWindows = Platform.isWindows;

  HTFileSystemSourceContext(
      {String? root,
      List<HTFilterConfig> includedFilter = const [],
      List<HTFilterConfig> excludedFilter = const [],
      Map<String, HTSource>? cache})
      : _cached = cache ?? <String, HTSource>{} {
    root = root != null ? path.absolute(root) : path.current;
    this.root = root =
        HTResourceContext.getAbsolutePath(dirName: root, isWindows: isWindows);
    final dir = Directory(root);
    final folderFilter = HTFilterConfig(root);
    final entities = dir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File) {
        final fileFullName = HTResourceContext.getAbsolutePath(
            key: entity.path, dirName: root, isWindows: isWindows);
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
  bool contains(String fullName) {
    final normalized = HTResourceContext.getAbsolutePath(
        key: fullName, dirName: root, isWindows: isWindows);
    return path.isWithin(root, normalized);
  }

  @override
  void addResource(String fullName, HTSource resource) {
    final normalized = HTResourceContext.getAbsolutePath(
        key: fullName, dirName: root, isWindows: isWindows);
    resource.name = normalized;
    // final source = HTSource(content,
    //     name: normalized, type: type, isLibraryEntry: isLibraryEntry);
    _cached[normalized] = resource;
    included.add(normalized);
    // return source;
  }

  @override
  void removeResource(String fullName) {
    final normalized = HTResourceContext.getAbsolutePath(
        key: fullName, dirName: root, isWindows: isWindows);
    _cached.remove(normalized);
    included.remove(normalized);
  }

  @override
  HTSource getResource(String key, {String? from}) {
    final normalized = HTResourceContext.getAbsolutePath(
        key: key,
        dirName: from != null ? path.dirname(from) : root,
        isWindows: isWindows);
    if (_cached.containsKey(normalized)) {
      return _cached[normalized]!;
    } else {
      final content = File(normalized).readAsStringSync();
      final source = HTSource(content, name: normalized);
      // final source = HTSource(content,
      //     name: normalized, type: type, isLibraryEntry: isLibraryEntry);
      _cached[normalized] = source;
      return source;
    }
  }

  @override
  void updateResource(String fullName, HTSource resource) {
    final normalized =
        HTResourceContext.getAbsolutePath(key: fullName, isWindows: isWindows);
    if (!_cached.containsKey(normalized)) {
      throw HTError.sourceProviderError(normalized);
    } else {
      // final source = _cached[normalized]!;
      // source.content = resource;
      _cached[normalized] = resource;
    }
  }

  // [fullPath] must be a normalized absolute path
  bool _filterFile(String fileName, HTFilterConfig filter) {
    final ext = path.extension(fileName);
    final normalizedFilePath = HTResourceContext.getAbsolutePath(
        key: fileName, dirName: root, isWindows: isWindows);
    final normalizedFolderPath = HTResourceContext.getAbsolutePath(
        key: filter.folder, dirName: root, isWindows: isWindows);
    if (path.isWithin(normalizedFolderPath, normalizedFilePath)) {
      if (filter.recursive) {
        return _checkExt(ext, filter.extention);
      } else {
        final fileDirName = path.basename(path.dirname(fileName));
        final folderDirName = path.basename(normalizedFolderPath);
        if (fileDirName == folderDirName) {
          return _checkExt(ext, filter.extention);
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
