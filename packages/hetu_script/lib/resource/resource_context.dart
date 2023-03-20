// import 'dart:io';

import 'package:path/path.dart' as path;

import '../resource/resource.dart';
// import 'file_system/file_system_context.dart';
// import 'overlay/overlay_context.dart';

/// A filter used by source context for reading files with certain extensions and/or within certain folders.
class HTFilterConfig {
  String folder;

  List<String> extension;

  bool recursive;

  HTFilterConfig(this.folder,
      {this.extension = const [
        HTResource.hetuModule,
        HTResource.hetuScript,
        HTResource.json,
        HTResource.json5,
      ],
      this.recursive = true});

  // [fullPath] must be a normalized absolute path
  bool isWithin(String fullPath) {
    final ext = path.extension(fullPath);
    if (path.isWithin(folder, fullPath)) {
      if (recursive) {
        return _checkExt(ext, extension);
      } else {
        final fileDirName = path.basename(path.dirname(fullPath));
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

  static const List<String> _predefinedCompatibleHetuValueExtensions = [
    HTResource.json,
    HTResource.json5
  ];

  List<String> get binaryFileExtensions => const [];

  void init() {}

  HTResourceType checkExtension(String ext) {
    if (ext == HTResource.hetuModule) {
      return HTResourceType.hetuModule;
    } else if (ext == HTResource.hetuScript) {
      return HTResourceType.hetuScript;
    } else if (_predefinedCompatibleHetuValueExtensions.contains(ext)) {
      return HTResourceType.json;
    } else if (binaryFileExtensions.contains(ext)) {
      return HTResourceType.binary;
    } else {
      return HTResourceType.unknown;
    }
  }

  /// Get a unique absolute normalized path.
  String getAbsolutePath({String key = '', String? dirName, String? filename}) {
    // if (key.startsWith(HTResourceContext.hetuLocalPackagePrefix)) {
    //   return '$root$defaultLocalPackagesFolder/${key.substring(4)}/$hetuModuleEntryFileName';
    // } else {
    var fullName = key;
    if (!path.isAbsolute(fullName)) {
      if (dirName != null) {
        fullName = path.join(dirName, key);
      } else {
        fullName = path.join(root, key);
      }
      if (!path.isAbsolute(fullName)) {
        fullName = path.join(path.current, fullName);
      }
    }
    assert(path.isAbsolute(fullName));
    if (filename != null) {
      fullName = path.join(fullName, filename);
    }
    final encoded = Uri.file(fullName).path;
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
