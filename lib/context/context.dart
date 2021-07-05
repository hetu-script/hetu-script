import 'dart:io';

import 'package:path/path.dart' as path;

import '../error/error.dart';
import '../source/source.dart';

class HTFilterConfig {
  final String folder;

  final List<String> extention;

  final recursive;

  HTFilterConfig(this.folder,
      {this.extention = const [], this.recursive = true});
}

class HTContext {
  late final String root;

  final included = <String>[];

  final Map<String, HTSource> _cachedSources;

  /// Create a [HTContextManagerImpl] with a certain [root],
  /// which is used to determin a module's absolute path
  /// when no relative path exists
  HTContext(
      {String? rootPath,
      List<HTFilterConfig> includedFilter = const [],
      List<HTFilterConfig> excludedFilter = const [],
      Map<String, HTSource>? cache})
      : _cachedSources = cache ?? <String, HTSource>{} {
    rootPath = rootPath != null ? path.absolute(rootPath) : path.current;
    root = getAbsolutePath(dirName: rootPath);
    final dir = Directory(root);
    final folderFilter = HTFilterConfig(root);
    final entities = dir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File) {
        final fileFullName = getAbsolutePath(pathName: entity.path);
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

  /// Import a script module with a certain [key], ignore those already imported
  ///
  /// If [from] is provided, the handler will try to get a relative path
  ///
  /// Otherwise, a absolute path is calculated from [root]
  HTSource getSource(String key,
      {String? from,
      SourceType type = SourceType.module,
      bool isLibraryEntry = false}) {
    final fullName = path.isAbsolute(key)
        ? key
        : getAbsolutePath(
            pathName: key, dirName: from != null ? path.dirname(from) : null);

    final content = File(fullName).readAsStringSync();
    final source = HTSource(content,
        fullName: fullName, type: type, isLibraryEntry: isLibraryEntry);

    _cachedSources[fullName] = source;
    return source;
  }

  String getAbsolutePath(
      {String pathName = '', String? dirName, String? fileName}) {
    if (!path.isAbsolute(pathName)) {
      if (dirName != null) {
        pathName = path.join(dirName, pathName);
      } else {
        pathName = path.join(root, pathName);
      }
    }
    if (fileName != null) {
      pathName = path.join(pathName, fileName);
    }
    final normalized = Uri.file(pathName).normalizePath().path;
    if (Platform.isWindows && normalized.startsWith('/')) {
      return normalized.substring(1);
    } else {
      return normalized;
    }
  }

  void changeContent(String fullName, String content) {
    if (!_cachedSources.containsKey(fullName)) {
      throw HTError.souceProviderError(
          fullName, 'Source provider error: could not load file with path');
    } else {
      final source = _cachedSources[fullName]!;
      source.content = content;
    }
  }

  // [fullPath] must be a normalized absolute path
  bool _filterFile(String fullName, HTFilterConfig filter) {
    final ext = path.extension(fullName);
    final normalizedFolder = getAbsolutePath(pathName: filter.folder);
    if (fullName.startsWith(normalizedFolder)) {
      if (filter.recursive) {
        return _checkExt(ext, filter.extention);
      } else {
        final fileDirName = path.dirname(fullName);
        final folderDirName = path.dirname(normalizedFolder);
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
