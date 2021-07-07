enum ErrorHanldeApproach {
  ingore,
  stdout,
  exception,
  log,
}

abstract class ErrorHandlerConfig {
  factory ErrorHandlerConfig(
      {bool stackTrace = true,
      int hetuStackTraceThreshhold = 10,
      ErrorHanldeApproach approach = ErrorHanldeApproach.exception}) {
    return ErrorHandlerConfigImpl(
        stackTrace: stackTrace,
        hetuStackTraceThreshhold: hetuStackTraceThreshhold,
        approach: approach);
  }

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

typedef HTErrorHandlerCallback = void Function(Object error,
    {Object? externalStackTrace});

/// Abstract error handler class
abstract class HTErrorHandler {
  ErrorHandlerConfig get errorConfig;

  void handleError(Object error, {Object? externalStackTrace});
}

/// Default error handler implementation
class HTErrorHandlerImpl implements HTErrorHandler {
  @override
  final ErrorHandlerConfig errorConfig;

  List errors = [];

  HTErrorHandlerImpl({ErrorHandlerConfig? config})
      : errorConfig = config ?? ErrorHandlerConfig();

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
      case ErrorHanldeApproach.log:
        errors.add(error);
        break;
    }
  }
}
