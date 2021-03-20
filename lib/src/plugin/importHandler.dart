import 'dart:io';
import 'package:path/path.dart' as path;

class HTModuleInfo {
  final String fileName;
  final String content;
  HTModuleInfo(this.fileName, this.content);
}

abstract class HTImportHandler {
  Future<HTModuleInfo> import(String key, [String? curDir]);
}

class DefaultImportHandler implements HTImportHandler {
  late final String workingDirectory;

  final imported = <String>[];

  DefaultImportHandler({String workingDirectory = 'script/'}) {
    final dir = Directory(workingDirectory);
    this.workingDirectory = dir.absolute.path;
  }

  @override
  Future<HTModuleInfo> import(String key, [String? curFileName]) async {
    late final String filePath;
    if (curFileName != null) {
      filePath = path.dirname(curFileName);
    } else {
      filePath = workingDirectory;
    }

    final fileName = path.join(filePath, key);

    var content = '';
    if (!imported.contains(fileName)) {
      imported.add(fileName);
      content = await File(fileName).readAsString();
    }

    return HTModuleInfo(fileName, content);
  }
}
