import 'dart:io';
import 'package:path/path.dart' as path;

class HTModuleInfo {
  final String filePath;
  final String content;
  HTModuleInfo(this.filePath, this.content);
}

abstract class HTImportHandler {
  Future<HTModuleInfo> import(String key);
}

class DefaultImportHandler implements HTImportHandler {
  late final String workingDirectory;

  final imported = <String>[];

  DefaultImportHandler({String workingDirectory = 'script/'}) {
    final dir = Directory(workingDirectory);
    this.workingDirectory = dir.absolute.path;
  }

  @override
  Future<HTModuleInfo> import(String key) async {
    final filePath = path.join(workingDirectory, key);
    var content = '';
    if (!imported.contains(filePath)) {
      imported.add(filePath);
      content = await File(filePath).readAsString();
    }

    return HTModuleInfo(filePath, content);
  }
}
