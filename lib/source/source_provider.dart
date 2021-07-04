import 'dart:io';

import 'package:path/path.dart' as path;

import '../grammar/semantic.dart';
import '../error/error.dart';
import 'context.dart';
import 'source.dart';

class HTFilterConfig {
  final String folder;

  final List<String> extention;

  final recursive;

  HTFilterConfig(this.folder,
      {this.extention = const [], this.recursive = true});
}

/// Abstract module import handler class
abstract class HTSourceProvider {
  String get root;

  bool hasSource(String path);

  String normalizeAbsolutePath(String key, {String? fileName, String? dirName});

  HTSource getSource(String key,
      {String? from,
      SourceType type = SourceType.module,
      bool isLibraryEntry = true,
      bool reload = true});

  void changeContent(String key, String content);

  HTContext getContext(String root,
      {List<HTFilterConfig> includedFilter = const [],
      List<HTFilterConfig> excludedFilter = const []});
}

/// A [HTSourceProvider] implementation handling file system
class DefaultSourceProvider implements HTSourceProvider {
  /// Absolute path used when no relative path exists
  @override
  late final String root;

  /// Sources will only load once
  final _cachedSources = <String, HTSource>{};

  /// Create a [DefaultSourceProvider] with a certain [root],
  /// which is used to determin a module's absolute path
  /// when no relative path exists
  DefaultSourceProvider({String? defaultPath}) {
    final dir = defaultPath != null
        ? Directory(defaultPath).absolute.path
        : Directory.current.absolute.path;

    root = normalizeAbsolutePath(dir, fileName: 'script');
  }

  @override
  bool hasSource(String key) => _cachedSources.containsKey(key);

  /// Turn a uri into a unique absolute path
  @override
  String normalizeAbsolutePath(String key,
      {String? fileName, String? dirName}) {
    if (!path.isAbsolute(key)) {
      if (dirName != null && !dirName.startsWith(SemanticNames.anonymous)) {
        key = path.join(dirName, key);
      } else {
        key = path.join(path.dirname(root), key);
      }
    }
    if (fileName != null) {
      key = path.join(key, fileName);
    }
    final normalized = Uri.file(key).normalizePath().path;
    if (Platform.isWindows && normalized.startsWith('/')) {
      return normalized.substring(1);
    } else {
      return normalized;
    }
  }

  /// Import a script module with a certain [key], ignore those already imported
  ///
  /// If [from] is provided, the handler will try to get a relative path
  ///
  /// Otherwise, a absolute path is calculated from [root]
  @override
  HTSource getSource(String key,
      {String? from,
      SourceType type = SourceType.module,
      bool isLibraryEntry = true,
      bool reload = true}) {
    final fullName = normalizeAbsolutePath(key,
        dirName: from != null ? path.dirname(from) : null);
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

  @override
  void changeContent(String fullName, String content) {
    if (!_cachedSources.containsKey(fullName)) {
      throw HTError.souceProviderError(
          fullName, 'Source provider error: could not load file with path');
    } else {
      final source = _cachedSources[fullName]!;
      source.content = content;
    }
  }

  @override
  HTContext getContext(String rootPath,
      {List<HTFilterConfig> includedFilter = const [],
      List<HTFilterConfig> excludedFilter = const []}) {
    final rootDir = Directory(rootPath);
    final normalizedRootPath = normalizeAbsolutePath(rootPath);
    final rootFilter = HTFilterConfig(normalizedRootPath);
    final includedFiles = <String>[];
    final entities = rootDir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File) {
        final fileFullName = normalizeAbsolutePath(entity.path);
        var isIncluded = false;
        if (includedFilter.isEmpty) {
          isIncluded =
              _filterFile(fileFullName, rootFilter, normalizedRootPath);
        } else {
          for (final filter in includedFilter) {
            if (_filterFile(fileFullName, filter, normalizedRootPath)) {
              isIncluded = true;
              break;
            }
          }
        }
        if (isIncluded) {
          if (excludedFilter.isNotEmpty) {
            for (final filter in excludedFilter) {
              final isExcluded =
                  _filterFile(fileFullName, filter, normalizedRootPath);
              if (isExcluded) {
                isIncluded = false;
                break;
              }
            }
          }
        }
        if (isIncluded) {
          includedFiles.add(fileFullName);
        }
      }
    }
    final context = HTContext(normalizedRootPath, included: includedFiles);
    return context;
  }

  List<HTContext> getContexts(List<String> openedFiles,
      {List<HTFilterConfig> excludedFilter = const []}) {
    final contexts = <HTContext>[];

    return contexts;
  }

  // [fullPath] must be a normalized absolute path
  bool _filterFile(
      String fullName, HTFilterConfig filter, String rootFullName) {
    final ext = path.extension(fullName);
    final filterFolder = path.isAbsolute(filter.folder)
        ? filter.folder
        : path.join(rootFullName, filter.folder);
    final normalizedFilterFolder = normalizeAbsolutePath(filterFolder);
    if (fullName.startsWith(normalizedFilterFolder)) {
      if (filter.recursive) {
        return _checkExt(ext, filter.extention);
      } else {
        final fileDirName = path.dirname(fullName);
        final folderDirName = path.dirname(normalizedFilterFolder);
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
