import 'dart:io';
import 'package:path/path.dart' as path;

import '../src/errors.dart';

/// Result of module handler's import function
class ImportResult {
  /// To tell a duplicated module
  final String fullName;

  /// The string content of the module
  final String content;

  /// If true, this is a duplicated module,
  /// the content will be a empty string
  final bool duplicate;
  ImportResult(this.fullName, this.content, {this.duplicate = false});
}

/// Abstract module import handler class
abstract class HTModuleHandler {
  bool hasModule(String path);

  String? getString(String path);

  Future<ImportResult> import(String key,
      {String? curFilePath, bool checkDuplicate = true});

  ImportResult importSync(String key,
      {String? curFilePath, bool checkDuplicate = true});
}

/// Default module import handler implementation
class DefaultModuleHandler implements HTModuleHandler {
  /// Absolute path used when no relative path exists
  late final String workingDirectory;

  /// Saved module name list
  final _importedFiles = <String, String>{};

  /// Create a DefaultModuleHandler with a certain [workingDirectory],
  /// which is used to determin a module's absolute path
  /// when no relative path exists
  DefaultModuleHandler({String? workingDirectory}) {
    if (workingDirectory != null) {
      final dir = Directory(workingDirectory);
      this.workingDirectory = dir.absolute.path;
    } else {
      final dir = Directory.current;
      this.workingDirectory = dir.absolute.path;
    }
  }

  @override
  bool hasModule(String key) => _importedFiles.containsKey(key);

  @override
  String? getString(String key) => _importedFiles[key];

  String _resolvePath(String key, [String? curFilePath]) {
    late final String filePath;
    if (curFilePath != null) {
      filePath = path.dirname(curFilePath);
    } else {
      filePath = workingDirectory;
    }

    return path.join(filePath, key);
  }

  /// Import a script module with a certain [key], ignore those already imported
  ///
  /// If [curFilePath] is provided, the handler will try to get a relative path
  ///
  /// Otherwise, a absolute path is calculated from [workingDirectory]
  @override
  Future<ImportResult> import(String key,
      {String? curFilePath, bool checkDuplicate = true}) async {
    try {
      var filePath = _resolvePath(key, curFilePath);

      var content = '';
      if (checkDuplicate && _importedFiles.containsKey(filePath)) {
        return ImportResult(filePath, content, duplicate: true);
      } else {
        content = await File(filePath).readAsString();
        if (content.isNotEmpty) {
          _importedFiles[filePath] = content;
          if (content.isEmpty) throw HTError.emptyString(filePath);
          return ImportResult(filePath, content);
        } else {
          throw HTError.emptyString(filePath);
        }
      }
    } catch (e) {
      throw HTError(e.toString(), HTErrorCode.dartError, HTErrorType.import);
    }
  }

  /// Synchronized version of [import].
  @override
  ImportResult importSync(String key,
      {String? curFilePath, bool checkDuplicate = true}) {
    try {
      var filePath = _resolvePath(key, curFilePath);

      var content = '';
      if (checkDuplicate && _importedFiles.containsKey(filePath)) {
        return ImportResult(filePath, content, duplicate: true);
      } else {
        content = File(filePath).readAsStringSync();
        if (content.isNotEmpty) {
          _importedFiles[filePath] = content;
          if (content.isEmpty) throw HTError.emptyString(filePath);
          return ImportResult(filePath, content);
        } else {
          throw HTError.emptyString(filePath);
        }
      }
    } catch (e) {
      throw HTError(e.toString(), HTErrorCode.dartError, HTErrorType.import);
    }
  }
}
