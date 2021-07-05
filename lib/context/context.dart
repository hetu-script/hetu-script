import 'dart:io';

import 'package:path/path.dart' as path;

import '../grammar/semantic.dart';
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

  /// Sources will only load once
  final _cachedSources = <String, HTSource>{};

  /// Create a [HTContextManagerImpl] with a certain [root],
  /// which is used to determin a module's absolute path
  /// when no relative path exists
  HTContext(
      {String? rootPath,
      List<HTFilterConfig> includedFilter = const [],
      List<HTFilterConfig> excludedFilter = const []}) {
    rootPath = rootPath != null ? path.absolute(rootPath) : path.current;
    root = normalizeAbsolutePath(dirName: rootPath);
    final dir = Directory(root);
    final folderFilter = HTFilterConfig(root);
    final entities = dir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File) {
        final fileFullName = normalizeAbsolutePath(pathName: entity.path);
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

  String normalizeAbsolutePath(
      {String pathName = '', String? fileName, String? dirName}) {
    if (!path.isAbsolute(pathName)) {
      if (dirName != null && !dirName.startsWith(SemanticNames.anonymous)) {
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

  bool hasSource(String key) => _cachedSources.containsKey(key);

  /// Import a script module with a certain [key], ignore those already imported
  ///
  /// If [from] is provided, the handler will try to get a relative path
  ///
  /// Otherwise, a absolute path is calculated from [root]
  HTSource getSource(String key,
      {String? from,
      SourceType type = SourceType.module,
      bool isLibraryEntry = false,
      bool reload = false}) {
    final fullName = path.isAbsolute(key)
        ? key
        : normalizeAbsolutePath(
            pathName: key, dirName: from != null ? path.dirname(from) : null);
    if (!_cachedSources.containsKey(fullName) || reload) {
      final content = File(fullName).readAsStringSync();
      final source = HTSource(content,
          fullName: fullName, type: type, isLibraryEntry: isLibraryEntry);
      _cachedSources[fullName] = source;
      return source;
    } else {
      return _cachedSources[fullName]!;
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
    final normalizedFolder = normalizeAbsolutePath(pathName: filter.folder);
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
