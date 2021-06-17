import 'error.dart';

enum ErrorHanldeApproach {
  ingore,
  stdout,
  exception,
  list,
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
  void handle(HTError error, [List<HTError>? errorList]) {
    switch (approach) {
      case ErrorHanldeApproach.ingore:
        break;
      case ErrorHanldeApproach.stdout:
        print(error);
        break;
      case ErrorHanldeApproach.exception:
        throw (error);
      case ErrorHanldeApproach.list:
        errorList!.add(error);
    }
  }
}
