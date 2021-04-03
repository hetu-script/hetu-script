import '../errors.dart';

/// Abstract error handler class
abstract class HTErrorHandler {
  void handle(HTInterpreterError error);
}

/// Default error handler implementation
class DefaultErrorHandler implements HTErrorHandler {
  @override
  void handle(HTInterpreterError error) {
    throw (error);
  }
}
