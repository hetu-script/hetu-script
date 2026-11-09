import 'dart:io';

import 'package:path/path.dart' as path;

import 'binding_models.dart';
import 'binding_resolver.dart';

/// Options controlling binding generation.
class BindingGeneratorOptions {
  /// Directories containing Dart source files to scan.
  final List<String> userLibPaths;

  /// Output directory for generated `.g.dart` files.
  final String outputPath;

  /// Output directory for generated `.ht` files.
  final String scriptOutputPath;

  /// File or class name patterns to ignore.
  final List<String> ignores;

  /// If non-empty, only files matching these patterns are processed.
  final List<String> whitelist;

  /// Optional directory for writing intermediate JSON diagnostics.
  final String? jsonExportPath;

  const BindingGeneratorOptions({
    required this.userLibPaths,
    required this.outputPath,
    required this.scriptOutputPath,
    this.ignores = const [],
    this.whitelist = const [],
    this.jsonExportPath,
  });
}

/// Core binding generator.
///
/// Scans Dart source files, resolves `@HTBinding()` declarations, and produces
/// [BindingFile] models. Emitters convert these models into Dart and Hetu
/// source code.
class BindingGenerator {
  final BindingGeneratorOptions options;

  BindingGenerator(this.options);

  /// Scans all configured paths and resolves binding declarations.
  Future<List<BindingFile>> generate() async {
    final files = await _collectDartFiles();
    if (files.isEmpty) {
      return [];
    }

    final resolver = BindingResolver(
      includedPaths:
          options.userLibPaths.map((p) => path.normalize(path.absolute(p))).toList(),
    );
    final results = <BindingFile>[];
    for (final file in files) {
      final bindingFile = await resolver.resolveFile(file);
      if (!bindingFile.isEmpty) {
        results.add(bindingFile);
      }
    }
    return results;
  }

  Future<List<String>> _collectDartFiles() async {
    final files = <String>[];
    for (final root in options.userLibPaths) {
      final absoluteRoot = path.normalize(path.absolute(root));
      final dir = Directory(absoluteRoot);
      if (!dir.existsSync()) {
        continue;
      }
      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) continue;
        final filePath = entity.path;
        final fileName = path.basename(filePath);
        if (!filePath.endsWith('.dart')) continue;
        if (fileName.startsWith('_')) continue;
        if (filePath.endsWith('.g.dart')) continue;
        if (!_matchesWhitelist(filePath)) continue;
        if (_isIgnored(filePath)) continue;
        files.add(filePath);
      }
    }
    return files;
  }

  bool _matchesWhitelist(String filePath) {
    if (options.whitelist.isEmpty) return true;
    return options.whitelist.any((pattern) => filePath.contains(pattern));
  }

  bool _isIgnored(String filePath) {
    return options.ignores.any((pattern) {
      if (pattern.contains(':')) {
        final index = pattern.indexOf(':');
        final filePattern = pattern.substring(0, index);
        return filePath.contains(filePattern);
      }
      return filePath.contains(pattern);
    });
  }
}
