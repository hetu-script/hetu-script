// import 'dart:io';

import 'package:path/path.dart' as path;

import '../resource/resource.dart';
// import 'file_system/file_system_context.dart';
// import 'overlay/overlay_context.dart';

class HTFilterConfig {
  String folder;

  List<String> extension;

  bool recursive;

  HTFilterConfig(this.folder,
      {this.extension = const [
        HTResource.hetuModule,
        HTResource.hetuScript,
      ],
      this.recursive = true});

  // [fullPath] must be a normalized absolute path
  bool isWithin(String fileName) {
    final ext = path.extension(fileName);
    if (path.isWithin(folder, fileName)) {
      if (recursive) {
        return _checkExt(ext, extension);
      } else {
        final fileDirName = path.basename(path.dirname(fileName));
        final folderDirName = path.basename(folder);
        if (fileDirName == folderDirName) {
          return _checkExt(ext, extension);
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

/// [HTResourceContext] are a set of resources, each has a unique path.
/// It could be a physical folder, a virtual collection in memory,
/// an URL, or a remote database... any thing that provide
/// create, read, update, delete services could be a resource context.
///
/// If the import path starts with 'package:',
/// will try to fetch the source file from '.hetu_modules' under root
///
/// If the import path starts with 'module:', then the module should be
/// already loaded by the loadBytecode() method.
abstract class HTResourceContext<T> {
  static const hetuPreloadedModulesPrefix = 'module:';
  static const hetuLocalPackagePrefix = 'package:';
  static const defaultLocalPackagesFolder = '.hetu_packages';
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

  List<String> get expressionModuleExtensions => const [];
  List<String> get binaryModuleExtensions => const [];

  void init() {}

  HTResourceType checkExtension(String ext) {
    if (ext == HTResource.hetuModule) {
      return HTResourceType.hetuModule;
    } else if (ext == HTResource.hetuScript) {
      return HTResourceType.hetuScript;
    } else if (expressionModuleExtensions.contains(ext)) {
      return HTResourceType.hetuValue;
    } else if (binaryModuleExtensions.contains(ext)) {
      return HTResourceType.binary;
    } else {
      return HTResourceType.unkown;
    }
  }

  /// Get a unique absolute normalized path.
  String getAbsolutePath({String key = '', String? dirName, String? fileName}) {
    // if (key.startsWith(HTResourceContext.hetuLocalPackagePrefix)) {
    //   return '$root$defaultLocalPackagesFolder/${key.substring(4)}/$hetuModuleEntryFileName';
    // } else {
    var name = key;
    if (!path.isAbsolute(name)) {
      if (dirName != null) {
        name = path.join(dirName, name);
      }
      if (!path.isAbsolute(name)) {
        name = path.join(path.current, name);
      }
    }
    if (fileName != null) {
      name = path.join(name, fileName);
    }
    final encoded = Uri.file(name).path;
    final normalized = Uri.decodeFull(encoded);
    return normalized;
    // }
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

  /// Import a resource with a certain [key], ignore those already imported
  ///
  /// If [from] is provided, the handler will try to get a relative path
  ///
  /// Otherwise, a absolute path is calculated from [root]
  T getResource(String key, {String? from});

  void updateResource(String fullName, T resource);
}
