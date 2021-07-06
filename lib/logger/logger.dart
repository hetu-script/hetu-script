import 'dart:io';

import 'package:path/path.dart' as path;

import '../error/error_severity.dart';
import '../util/util.dart';

abstract class HTLogger {
  String? folder;

  void log(String message, [ErrorSeverity severity = ErrorSeverity.info]);

  void dump();
}

class HTFileSystemLogger implements HTLogger {
  late String _fileName;

  @override
  String? folder;

  HTFileSystemLogger() {
    dump();
  }

  @override
  void log(String message, [ErrorSeverity severity = ErrorSeverity.info]) {
    if (folder == null) {
      return;
    }
    final output =
        '${DateTime.now().toIso8601String()} ${severity.displayName} - $message\n';
    final file = File(path.join(folder!, _fileName));
    file.writeAsStringSync(output, mode: FileMode.append);
  }

  @override
  void dump() {
    final now = DateTime.now();
    _fileName =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${char4() + char4()}.txt';
  }
}
