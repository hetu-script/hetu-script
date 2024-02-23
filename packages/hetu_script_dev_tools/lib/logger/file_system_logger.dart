import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:hetu_script/logger/logger.dart';
import 'package:hetu_script/logger/message_severity.dart';

import '../util/uid.dart';

class HTFileSystemLogger extends HTLogger {
  late String _fileName;

  String? folder;

  HTFileSystemLogger() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    _fileName = '$year$month$day$hour$minute$second-${uid4() + uid4()}.txt';
  }

  @override
  void log(dynamic message, {MessageSeverity severity = MessageSeverity.info}) {
    if (folder == null) {
      return;
    }
    final output =
        '${DateTime.now().toIso8601String()} ${severity.displayName} - $message\n';
    final file = File(path.join(folder!, _fileName));
    file.writeAsStringSync(output, mode: FileMode.append);
  }
}
