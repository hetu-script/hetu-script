import 'dart:io';

import 'package:path/path.dart' as path;

import '../error/error.dart';
import '../error/error_handler.dart';
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
abstract class HTSourceProvider {
  String get workingDirectory;

  HTErrorHandler get errorHandler;

  bool hasModule(String path);

  String resolveFullName(String key, [String? currentModuleFullName]);

  HTSource? getSourceSync(String key,
      {bool isFullName = false,
      String? from,
      bool reload = true,
      ErrorType errorType = ErrorType.runtimeError,
      int? line,
      int? column});
}

/// Default module import handler implementation
class DefaultSourceProvider implements HTSourceProvider {
  /// Absolute path used when no relative path exists
  @override
  late final String workingDirectory;

  @override
  HTErrorHandler errorHandler;

  /// Saved module name list
  final _cached = <String, HTSource>{};

  /// Create a [DefaultSourceProvider] with a certain [workingDirectory],
  /// which is used to determin a module's absolute path
  /// when no relative path exists
  DefaultSourceProvider(
      {String? workingDirectory, HTErrorHandler? errorHandler})
      : errorHandler = errorHandler ?? DefaultErrorHandler() {
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
  bool hasModule(String key) => _cached.containsKey(key);

  @override
  String resolveFullName(String key, [String? from]) {
    late final String fullName;
    if ((from != null) && !from.startsWith(SemanticNames.anonymousScript)) {
      fullName = path.dirname(from);
    } else {
      fullName = workingDirectory;
    }

    var joined = path.join(fullName, key);
    var result = Uri.file(joined).path.trimPath();
    return result;
  }

  /// Import a script module with a certain [key], ignore those already imported
  ///
  /// If [from] is provided, the handler will try to get a relative path
  ///
  /// Otherwise, a absolute path is calculated from [workingDirectory]
  @override
  HTSource? getSourceSync(String key,
      {bool isFullName = false,
      String? from,
      SourceType type = SourceType.module,
      bool isLibrary = false,
      String? libraryName,
      bool reload = true,
      ErrorType errorType = ErrorType.runtimeError,
      int? line,
      int? column}) {
    try {
      final fullName = isFullName ? key : resolveFullName(key, from);
      if (!_cached.containsKey(fullName) || reload) {
        final content = File(fullName).readAsStringSync();
        if (content.isEmpty) {
          throw HTError.emptyString(
              type: errorType,
              info: fullName,
              moduleFullName: from,
              line: line,
              column: column);
        }
        final source = HTSource(fullName, content,
            type: type, isLibrary: isLibrary, libraryName: libraryName);
        _cached[fullName] = source;
        return source;
      } else {
        return _cached[fullName]!;
      }
    } catch (e) {
      if (e is HTError) {
        errorHandler.handleError(e);
      } else {
        final err = HTError.nonExistModule(key, errorType,
            moduleFullName: from, line: line, column: column);
        errorHandler.handleError(err);
      }
    }
  }
}
