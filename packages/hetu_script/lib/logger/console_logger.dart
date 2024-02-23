import '../logger/message_severity.dart';
import 'logger.dart';

class HTConsoleLogger extends HTLogger {
  const HTConsoleLogger();

  @override
  void log(String message, {MessageSeverity severity = MessageSeverity.none}) {
    print(message);
  }
}
