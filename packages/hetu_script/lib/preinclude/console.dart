import '../logger/message_severity.dart';
import '../lexicon/lexicon.dart';
import '../logger/logger.dart';
import '../logger/console_logger.dart';

class Console {
  HTLexicon lexicon;
  HTLogger logger;

  static const _defaultTimerId = 'default';
  final Map<String, int> _tiks = {};

  Console({
    required this.lexicon,
    this.logger = const HTConsoleLogger(),
  });

  void log(dynamic messages,
      {MessageSeverity severity = MessageSeverity.none}) {
    if (messages is List) {
      messages = messages.map((e) => lexicon.stringify(e)).join(' ');
    } else {
      messages = lexicon.stringify(messages);
    }
    logger.log(messages, severity: severity);
  }

  void debug(dynamic messages) =>
      log(messages, severity: MessageSeverity.debug);

  void info(dynamic messages) => log(messages, severity: MessageSeverity.info);

  void warn(dynamic messages) => log(messages, severity: MessageSeverity.warn);

  void error(dynamic messages) =>
      log(messages, severity: MessageSeverity.error);

  void time(String? id) {
    id ??= _defaultTimerId;
    if (_tiks.containsKey(id)) {
      warn('Timer \'$id\' already exists.');
    } else {
      _tiks[id] = DateTime.now().millisecondsSinceEpoch;
    }
  }

  void timeLog(String? id, {bool endTimer = false}) {
    id ??= _defaultTimerId;
    if (_tiks.containsKey(id)) {
      log('$id: ${DateTime.now().millisecondsSinceEpoch - _tiks[id]!} ms');
      if (endTimer) {
        _tiks.remove(id);
      }
    } else {
      warn('Timer \'$id\' does not exist.');
    }
  }

  void timeEnd(String? id) {
    timeLog(id, endTimer: true);
  }
}
