import '../errors.dart';

/// Abstract error handler class
abstract class HTErrorHandler {
  void handle(HTError error);
}

/// Default error handler implementation
class DefaultErrorHandler implements HTErrorHandler {
  @override
  void handle(HTError error) {
    throw (error);
  }
}
