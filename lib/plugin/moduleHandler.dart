import 'dart:io';
import 'package:path/path.dart' as path;

import '../src/errors.dart';

/// Result of module handler's import function
class HTModuleInfo {
  /// To tell a duplicated module
  final String fullName;

  /// The string content of the module
  final String content;

  /// If true, this is a duplicated module,
  /// the content will be a empty string
  final bool duplicate;
  HTModuleInfo(this.fullName, this.content, {this.duplicate = false});
}

/// Abstract module import handler class
abstract class HTModuleHandler {
  Future<HTModuleInfo> import(String key, [String? curFileName]);
}

/// Default module import handler implementation
class DefaultModuleHandler implements HTModuleHandler {
  /// Absolute path used when no relative path exists
  late final String workingDirectory;

  /// Saved module name list
  final imported = <String>[];

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

  /// Fetch a script module with a certain [key]
  ///
  /// If [curFilePath] is provided, the handler will try to get a relative path
  ///
  /// Otherwise, a absolute path is calculated from [workingDirectory]
  @override
  Future<HTModuleInfo> import(String key, [String? curFilePath]) async {
    var fileName = key;
    try {
      late final String filePath;
      if (curFilePath != null) {
        filePath = path.dirname(curFilePath);
      } else {
        filePath = workingDirectory;
      }

      fileName = path.join(filePath, key);

      var content = '';
      if (!imported.contains(fileName)) {
        imported.add(fileName);
        content = await File(fileName).readAsString();
        if (content.isEmpty) throw HTError.emptyString(fileName);
        return HTModuleInfo(fileName, content);
      } else {
        return HTModuleInfo(fileName, content, duplicate: true);
      }
    } catch (e) {
      throw (HTError(e.toString(), HTErrorCode.dartError, HTErrorType.import));
    }
  }
}
