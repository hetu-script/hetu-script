import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;
import 'package:hetu_script/hetu_script.dart';

class HTAssetResourceContext extends HTResourceContext<HTSource> {
  @override
  final String root;

  @override
  Set<String> get included => _cached.keys.toSet();

  final _cached = <String, HTSource>{};

  final List<HTFilterConfig> _includedFilter;
  final List<HTFilterConfig> _excludedFilter;
  @override
  final List<String> expressionModuleExtensions;
  @override
  final List<String> binaryModuleExtensions;

  /// Create a [HTAssetResourceContext] with every script file
  /// placed under folder of [root], which defaults to 'scripts/'
  HTAssetResourceContext(
      {this.root = 'scripts/',
      List<HTFilterConfig> includedFilter = const [],
      List<HTFilterConfig> excludedFilter = const [],
      this.expressionModuleExtensions = const [],
      this.binaryModuleExtensions = const []})
      : _includedFilter = includedFilter,
        _excludedFilter = excludedFilter;

  @override
  Future<void> init() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final assetKeys = manifestMap.keys;
    final folderFilter = HTFilterConfig(root);
    final includedKeys = <String>[];
    for (final key in assetKeys) {
      var isIncluded = false;
      if (_includedFilter.isEmpty) {
        isIncluded = folderFilter.isWithin(key);
      } else {
        for (final filter in _includedFilter) {
          if (filter.isWithin(key)) {
            isIncluded = true;
            break;
          }
        }
      }
      if (isIncluded) {
        for (final filter in _excludedFilter) {
          final isExcluded = filter.isWithin(key);
          if (isExcluded) {
            isIncluded = false;
            break;
          }
        }
      }
      if (isIncluded) {
        includedKeys.add(key);
      }
    }
    for (final key in includedKeys) {
      final content = await rootBundle.loadString(key);
      final ext = path.extension(key);
      final source = HTSource(content, name: key, type: checkExtension(ext));
      addResource(key, source);
    }
  }

  String getFullName(String name) {
    late String fullName;
    if (name.startsWith(root)) {
      fullName = name;
    } else {
      fullName = path.join(root, name);
    }
    return fullName;
  }

  @override
  bool contains(String key) {
    return _cached.keys.contains(getFullName(key));
  }

  @override
  void addResource(String fullName, HTSource resource) {
    resource.name = fullName;
    _cached[fullName] = resource;
  }

  @override
  void removeResource(String fullName) {
    _cached.remove(fullName);
    included.remove(fullName);
  }

  @override
  HTSource getResource(String key, {String? from}) {
    var normalized = key;
    // if (!key.startsWith(HTResourceContext.hetuModulesPrefix)) {
    if (!key.startsWith(root)) {
      normalized = getAbsolutePath(
          key: key, dirName: from != null ? path.dirname(from) : root);
    }
    // }
    if (_cached.containsKey(normalized)) {
      return _cached[normalized]!;
    }
    throw HTError.sourceProviderError(normalized);
  }

  @override
  void updateResource(String fullName, HTSource resource) {
    if (!_cached.containsKey(fullName)) {
      throw HTError.sourceProviderError(fullName);
    }
    _cached[fullName] = resource;
  }
}
