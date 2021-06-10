import 'errors.dart';

enum ErrorHanldeApproach {
  IGNORE,
  THROW,
  LOG,
}

/// Abstract error handler class
abstract class HTErrorHandler {
  void handle(HTError error);
}

/// Default error handler implementation
class DefaultErrorHandler implements HTErrorHandler {
  const DefaultErrorHandler();

  @override
  void handle(HTError error) {
    throw (error);
  }
}
