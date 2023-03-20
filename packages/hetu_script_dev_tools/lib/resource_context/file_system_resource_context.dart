import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:hetu_script/hetu_script.dart';

/// [HTResourceContext] are a set of files and folders under a folder or a path.
class HTFileSystemResourceContext extends HTResourceContext<HTSource> {
  @override
  late final String root;

  @override
  final Set<String> included = <String>{};

  final Map<String, HTSource> _cached;

  @override
  final List<String> binaryFileExtensions;

  HTFileSystemResourceContext(
      {String? root,
      Map<String, HTSource>? cache,
      List<HTFilterConfig> includedFilter = const [],
      List<HTFilterConfig> excludedFilter = const [],
      this.binaryFileExtensions = const [],
      bool doScanRoot = false})
      : _cached = cache ?? <String, HTSource>{} {
    if (root != null) {
      this.root = root = getAbsolutePath(dirName: root);
    } else {
      this.root = root = getAbsolutePath(dirName: path.current);
    }

    if (doScanRoot) {
      final dir = Directory(root);
      final folderFilter = HTFilterConfig(root);
      final entities = dir.listSync(recursive: true);
      for (final filter in includedFilter) {
        filter.folder = getAbsolutePath(key: filter.folder, dirName: root);
      }
      for (final filter in excludedFilter) {
        filter.folder = getAbsolutePath(key: filter.folder, dirName: root);
      }
      for (final entity in entities) {
        if (entity is! File) {
          continue;
        }
        final fileFullName = getAbsolutePath(key: entity.path, dirName: root);
        var isIncluded = false;
        if (includedFilter.isEmpty) {
          isIncluded = folderFilter.isWithin(fileFullName);
        } else {
          for (final filter in includedFilter) {
            if (filter.isWithin(fileFullName)) {
              isIncluded = true;
              break;
            }
          }
        }
        if (isIncluded) {
          if (excludedFilter.isNotEmpty) {
            for (final filter in excludedFilter) {
              final isExcluded = filter.isWithin(fileFullName);
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
  String getAbsolutePath({String key = '', String? dirName, String? filename}) {
    final normalized =
        super.getAbsolutePath(key: key, dirName: dirName, filename: filename);
    if (Platform.isWindows && normalized.startsWith('/')) {
      return normalized.substring(1);
    } else {
      return normalized;
    }
  }

  @override
  bool contains(String key) {
    final normalized = getAbsolutePath(key: key, dirName: root);
    return path.isWithin(root, normalized);
  }

  @override
  void addResource(String fullName, HTSource resource) {
    final normalized = getAbsolutePath(key: fullName);
    resource.fullName = normalized;
    _cached[normalized] = resource;
    included.add(normalized);
  }

  @override
  void removeResource(String fullName) {
    final normalized = getAbsolutePath(key: fullName);
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
          HTSource(content, filename: normalized, type: checkExtension(ext));
      addResource(normalized, source);
      return source;
    }
  }

  @override
  void updateResource(String fullName, HTSource resource) {
    final normalized = getAbsolutePath(key: fullName);
    resource.fullName = normalized;
    if (!_cached.containsKey(normalized)) {
      throw HTError.resourceDoesNotExist(normalized);
    } else {
      _cached[normalized] = resource;
    }
  }
}
