import 'error.dart';

enum ErrorHanldeApproach {
  ingore,
  stdout,
  exception,
}

/// Abstract error handler class
abstract class HTErrorHandler {
  void handle(HTError error);
}

/// Default error handler implementation
class DefaultErrorHandler implements HTErrorHandler {
  final ErrorHanldeApproach approach;
  const DefaultErrorHandler({this.approach = ErrorHanldeApproach.exception});
  @override
  void handle(HTError error) {
    switch (approach) {
      case ErrorHanldeApproach.ingore:
        break;
      case ErrorHanldeApproach.stdout:
        print(error);
        break;
      case ErrorHanldeApproach.exception:
        throw (error);
    }
  }
}
