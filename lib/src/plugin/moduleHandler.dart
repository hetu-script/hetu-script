import 'dart:io';
import 'package:path/path.dart' as path;

import '../errors.dart';

class HTModuleInfo {
  final String fileName;
  final String content;
  final bool duplicate;
  HTModuleInfo(this.fileName, this.content, {this.duplicate = false});
}

abstract class HTModuleHandler {
  Future<HTModuleInfo> import(String key, [String? curFileName]);
}

class DefaultModuleHandler implements HTModuleHandler {
  late final String workingDirectory;

  final imported = <String>[];

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
  Future<HTModuleInfo> import(String key, [String? curFileName]) async {
    var fileName = key;
    try {
      late final String filePath;
      if (curFileName != null) {
        filePath = path.dirname(curFileName);
      } else {
        filePath = workingDirectory;
      }

      fileName = path.join(filePath, key);

      var content = '';
      if (!imported.contains(fileName)) {
        imported.add(fileName);
        content = await File(fileName).readAsString();
        if (content.isEmpty) throw HTErrorEmpty(fileName);
        return HTModuleInfo(fileName, content);
      } else {
        return HTModuleInfo(fileName, content, duplicate: true);
      }
    } catch (e) {
      throw (HTImportError(e.toString(), fileName));
    }
  }
}
