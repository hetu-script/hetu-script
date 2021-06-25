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

  HTSource getSourceSync(String key,
      {bool isFullName = false,
      String? from,
      bool reload = true,
      ErrorType errorType = ErrorType.runtimeError});
}

/// Default module import handler implementation
class DefaultSourceProvider implements SourceProvider {
  /// Absolute path used when no relative path exists
  @override
  late final String workingDirectory;

  /// Saved module name list
  final _cached = <String, HTSource>{};

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
  HTSource getSourceSync(String key,
      {bool isFullName = false,
      String? from,
      SourceType type = SourceType.module,
      bool isLibrary = false,
      String? libraryName,
      bool reload = true,
      ErrorType errorType = ErrorType.runtimeError}) {
    try {
      final fullName = isFullName ? key : resolveFullName(key, from);
      if (!_cached.containsKey(fullName) || reload) {
        final content = File(fullName).readAsStringSync();
        if (content.isNotEmpty) {
          if (content.isEmpty) throw HTError.emptyString(fullName);
          final source = HTSource(fullName, content,
              type: type, isLibrary: isLibrary, libraryName: libraryName);
          _cached[fullName] = source;
          return source;
        } else {
          throw HTError.emptyString(fullName);
        }
      } else {
        return _cached[fullName]!;
      }
    } catch (e) {
      if (e is HTError) {
        rethrow;
      } else {
        throw HTError.unknownModule(key, errorType);
      }
    }
  }
}
