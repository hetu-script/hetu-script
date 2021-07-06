import 'dart:io';

import 'package:path/path.dart' as path;

import '../source/source.dart';
import 'file_system/file_system_context.dart';

class HTFilterConfig {
  final String folder;

  final List<String> extention;

  final recursive;

  HTFilterConfig(this.folder,
      {this.extention = const [hetuSouceFileExtension], this.recursive = true});
}

/// [HTContext] are a set of files and folders under a folder or a path.
abstract class HTContext {
  /// Get a unique absolute normalized path.
  static String getAbsolutePath(
      {String key = '', String? dirName, String? fileName}) {
    if (!path.isAbsolute(key) && dirName != null) {
      key = path.join(dirName, key);
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

  /// Create a [HTFileSystemContext]
  factory HTContext.fileSystem(
      {String? root,
      List<HTFilterConfig> includedFilter,
      List<HTFilterConfig> excludedFilter,
      Map<String, HTSource>? cache}) = HTFileSystemContext;

  String get root;

  Iterable<String> get included;

  bool contains(String fileName);

  HTSource addSource(String fullName, String content,
      {SourceType type = SourceType.module, bool isLibraryEntry = false});

  /// Import a script module with a certain [key], ignore those already imported
  ///
  /// If [from] is provided, the handler will try to get a relative path
  ///
  /// Otherwise, a absolute path is calculated from [root]
  HTSource getSource(String key,
      {String? from,
      SourceType type = SourceType.module,
      bool isLibraryEntry = false});

  void updateSource(String fullName, String content);
}
