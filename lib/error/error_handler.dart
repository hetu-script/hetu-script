enum ErrorHanldeApproach {
  ingore,
  stdout,
  exception,
  list,
}

abstract class ErrorHandlerConfig {
  bool get stackTrace;

  int get hetuStackTraceThreshhold;

  ErrorHanldeApproach get approach;
}

class ErrorHandlerConfigImpl implements ErrorHandlerConfig {
  @override
  final bool stackTrace;

  @override
  final int hetuStackTraceThreshhold;

  @override
  final ErrorHanldeApproach approach;

  const ErrorHandlerConfigImpl(
      {this.stackTrace = true,
      this.hetuStackTraceThreshhold = 10,
      this.approach = ErrorHanldeApproach.exception});
}

/// Abstract error handler class
abstract class HTErrorHandler {
  ErrorHandlerConfig get errorConfig;

  void handleError(Object error, {Object? externalStackTrace});
}

/// Default error handler implementation
class DefaultErrorHandler implements HTErrorHandler {
  @override
  final ErrorHandlerConfig errorConfig;

  List errors = [];

  DefaultErrorHandler({this.errorConfig = const ErrorHandlerConfigImpl()});

  @override
  void handleError(Object error, {Object? externalStackTrace}) {
    switch (errorConfig.approach) {
      case ErrorHanldeApproach.ingore:
        break;
      case ErrorHanldeApproach.stdout:
        print(error);
        break;
      case ErrorHanldeApproach.exception:
        throw (error);
      case ErrorHanldeApproach.list:
        errors.add(error);
    }
  }
}
