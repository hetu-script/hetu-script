import 'message_severity.dart';

abstract class HTLogger {
  const HTLogger();

  void log(String message, {MessageSeverity severity = MessageSeverity.none});

  void debug(String message) => log(message, severity: MessageSeverity.debug);

  void info(String message) => log(message, severity: MessageSeverity.info);

  void warn(String message) => log(message, severity: MessageSeverity.warn);

  void error(String message) => log(message, severity: MessageSeverity.error);
}
