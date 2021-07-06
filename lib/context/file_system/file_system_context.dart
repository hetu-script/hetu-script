import 'dart:io';

import 'package:path/path.dart' as path;

import '../../error/error.dart';
import '../../source/source.dart';
import '../context.dart';

/// [HTContext] are a set of files and folders under a folder or a path.
class HTFileSystemContext implements HTContext {
  @override
  late final String root;

  @override
  final List<String> included = <String>[];

  final Map<String, HTSource> _cached;

  HTFileSystemContext(
      {String? root,
      List<HTFilterConfig> includedFilter = const [],
      List<HTFilterConfig> excludedFilter = const [],
      Map<String, HTSource>? cache})
      : _cached = cache ?? <String, HTSource>{} {
    root = root != null ? path.absolute(root) : path.current;
    this.root = root = HTContext.getAbsolutePath(dirName: root);
    final dir = Directory(root);
    final folderFilter = HTFilterConfig(root);
    final entities = dir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is File) {
        final fileFullName =
            HTContext.getAbsolutePath(key: entity.path, dirName: root);
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
    final normalized = HTContext.getAbsolutePath(key: fullName, dirName: root);
    return path.isWithin(root, normalized);
  }

  @override
  HTSource addSource(String fullName, String content,
      {SourceType type = SourceType.module, bool isLibraryEntry = false}) {
    final normalized = HTContext.getAbsolutePath(key: fullName, dirName: root);
    final source = HTSource(content,
        fullName: normalized, type: type, isLibraryEntry: isLibraryEntry);
    _cached[normalized] = source;
    return source;
  }

  @override
  HTSource getSource(String key,
      {String? from,
      SourceType type = SourceType.module,
      bool isLibraryEntry = false}) {
    final fullName = HTContext.getAbsolutePath(
        key: key, dirName: from != null ? path.dirname(from) : root);
    if (_cached.containsKey(fullName)) {
      return _cached[fullName]!;
    } else {
      final content = File(fullName).readAsStringSync();
      final source = HTSource(content,
          fullName: fullName, type: type, isLibraryEntry: isLibraryEntry);
      _cached[fullName] = source;
      return source;
    }
  }

  @override
  void updateSource(String fullName, String content) {
    if (!_cached.containsKey(fullName)) {
      throw HTError.souceProviderError(
          fullName, 'Context error: could not load file with path');
    } else {
      final source = _cached[fullName]!;
      source.content = content;
    }
  }

  // [fullPath] must be a normalized absolute path
  bool _filterFile(String fullName, HTFilterConfig filter) {
    final ext = path.extension(fullName);
    final normalizedFolder =
        HTContext.getAbsolutePath(key: filter.folder, dirName: root);
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
