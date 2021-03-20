import '../errors.dart';

abstract class HTErrorHandler {
  void handle(HTInterpreterError err);
}

class DefaultErrorHandler implements HTErrorHandler {
  @override
  void handle(HTInterpreterError err) {
    throw (err);
  }
}
