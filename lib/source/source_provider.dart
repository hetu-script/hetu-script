import 'dart:io';

import 'package:path/path.dart' as path;

import '../error/error.dart';
import '../grammar/semantic.dart';
import 'source.dart';

extension TrimPath on String {
  String trimPath() {
    if (Platform.isWindows && startsWith('/')) {
      return substring(1);
    }
    return this;
  }
}

/// Abstract module import handler class
abstract class SourceProvider {
  String get workingDirectory;

  bool hasModule(String path);

  String resolveFullName(String key, [String? currentModuleFullName]);

  Future<HTSource> getSource(String key,
      {bool isFullName = false,
      String? curModuleFullName,
      bool reload = true,
      ErrorType errorType = ErrorType.runtimeError});

  HTSource getSourceSync(String key, {String? curFilePath, bool reload = true});
}

/// Default module import handler implementation
class DefaultSourceProvider implements SourceProvider {
  /// Absolute path used when no relative path exists
  @override
  late final String workingDirectory;

  /// Saved module name list
  final _importedFiles = <String, String>{};

  /// Create a [DefaultSourceProvider] with a certain [workingDirectory],
  /// which is used to determin a module's absolute path
  /// when no relative path exists
  DefaultSourceProvider({String? workingDirectory}) {
    late final String dir;
    if (workingDirectory != null) {
      dir = Directory(workingDirectory).absolute.path;
    } else {
      dir = Directory.current.absolute.path;
    }
    var joined = path.join(dir, 'script');
    final workingPath = Uri.file(joined).path.trimPath();
    this.workingDirectory = workingPath;
  }

  @override
  bool hasModule(String key) => _importedFiles.containsKey(key);

  @override
  String resolveFullName(String key, [String? curModuleFullName]) {
    late final String fullName;
    if ((curModuleFullName != null) &&
        !curModuleFullName.startsWith(SemanticNames.anonymousScript)) {
      fullName = path.dirname(curModuleFullName);
    } else {
      fullName = workingDirectory;
    }

    var joined = path.join(fullName, key);
    var result = Uri.file(joined).path.trimPath();
    return result;
  }

  /// Import a script module with a certain [key], ignore those already imported
  ///
  /// If [curModuleFullName] is provided, the handler will try to get a relative path
  ///
  /// Otherwise, a absolute path is calculated from [workingDirectory]
  @override
  Future<HTSource> getSource(String key,
      {bool isFullName = false,
      String? curModuleFullName,
      bool reload = true,
      ErrorType errorType = ErrorType.runtimeError}) async {
    try {
      final fullName =
          isFullName ? key : resolveFullName(key, curModuleFullName);

      if (!hasModule(fullName) || reload) {
        final content = await File(fullName).readAsString();
        if (content.isNotEmpty) {
          _importedFiles[fullName] = content;
          if (content.isEmpty) throw HTError.emptyString(fullName);
          return HTSource(fullName, content);
        } else {
          throw HTError.emptyString(fullName);
        }
      } else {
        return HTSource(fullName, _importedFiles[fullName]!);
      }
    } catch (e) {
      if (e is HTError) {
        rethrow;
      } else {
        throw HTError.unknownModule(key, errorType);
      }
    }
  }

  /// Synchronized version of [evalFile].
  @override
  HTSource getSourceSync(String key,
      {String? curFilePath, bool reload = true}) {
    throw HTError(ErrorCode.external, ErrorType.externalError,
        message: 'getContentSync is currently unusable');
  }
}
