// import 'dart:io';

import 'package:path/path.dart' as path;

import '../source/source.dart';
// import 'file_system/file_system_context.dart';
// import 'overlay/overlay_context.dart';

class HTFilterConfig {
  final String folder;

  final List<String> extention;

  final bool recursive;

  HTFilterConfig(this.folder,
      {this.extention = const [
        HTSource.hetuModuleFileExtension,
        HTSource.hetuScriptFileExtension,
      ],
      this.recursive = true});
}

/// [HTResourceContext] are a set of resources, each has a unique path.
/// It could be a physical folder, a virtual collection in memory,
/// an URL, or a remote database... any thing that provide
/// create, read, update, delete services could be a resource context.
///
/// If the import path starts with 'mod:',
/// will try to fetch the source file from '.hetu_modules' under root
abstract class HTResourceContext<T> {
  static const hetuModulesPrefix = 'mod:';
  static const defaultLocalModulesFolder = '.hetu_modules';
  static const hetuModuleEntryFileName = 'main.ht';

  // static String checkHetuModuleName(String fileName) {
  //   if (fileName.contains(HTResourceContext.defaultLocalModulesFolder) &&
  //       fileName.endsWith(HTResourceContext.hetuModuleEntryFileName)) {
  //     final start =
  //         fileName.indexOf(HTResourceContext.defaultLocalModulesFolder) +
  //             HTResourceContext.defaultLocalModulesFolder.length;
  //     final end = fileName.indexOf('/', start);
  //     return fileName.substring(start, end);
  //   } else {
  //     return fileName;
  //   }
  // }

  /// Get a unique absolute normalized path.
  String getAbsolutePath({String key = '', String? dirName, String? fileName}) {
    if (key.startsWith(HTResourceContext.hetuModulesPrefix)) {
      return '$root$defaultLocalModulesFolder/${key.substring(4)}/$hetuModuleEntryFileName';
    } else {
      var name = key;
      if (!path.isAbsolute(name) && dirName != null) {
        name = path.join(dirName, name);
      }
      if (fileName != null) {
        name = path.join(name, fileName);
      }
      final normalized = Uri.file(name).path;
      return normalized;
    }
  }

  /// Create a [HTFileSystemContext]
  // factory HTContext.fileSystem(
  //     {String? root,
  //     List<HTFilterConfig> includedFilter,
  //     List<HTFilterConfig> excludedFilter,
  //     Map<String, HTSource>? cache}) = HTFileSystemContext;

  /// Create a [HTOverlayContext]
  // factory HTResourceContext.overlay(
  //     {String? root, Map<String, HTSource>? cache}) = HTOverlayContext;

  String get root;

  Iterable<String> get included;

  bool contains(String key);

  void addResource(String fullName, T resource);

  void removeResource(String fullName);

  /// Import a script module with a certain [key], ignore those already imported
  ///
  /// If [from] is provided, the handler will try to get a relative path
  ///
  /// Otherwise, a absolute path is calculated from [root]
  T getResource(String key, {String? from});

  void updateResource(String fullName, T resource);
}
