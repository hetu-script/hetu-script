enum ErrorHanldeApproach {
  ingore,
  stdout,
  exception,
  log,
}

const kStackTraceDisplayCountLimit = 5;

class ErrorHandlerConfig {
  bool showDartStackTrace;

  bool showHetuStackTrace;

  int stackTraceDisplayCountLimit;

  ErrorHanldeApproach errorHanldeApproach;

  ErrorHandlerConfig(
      {this.showDartStackTrace = false,
      this.showHetuStackTrace = false,
      this.stackTraceDisplayCountLimit = kStackTraceDisplayCountLimit,
      this.errorHanldeApproach = ErrorHanldeApproach.exception});
}

typedef HTErrorHandlerCallback = void Function(Object error,
    {Object? externalStackTrace});

/// Abstract error handler class
abstract class HTErrorHandler {
  ErrorHandlerConfig? get errorConfig;

  void handleError(Object error, [Object? externalStackTrace]);
}

/// Default error handler implementation
class HTErrorHandlerImpl implements HTErrorHandler {
  @override
  final ErrorHandlerConfig errorConfig;

  List errors = [];

  HTErrorHandlerImpl({ErrorHandlerConfig? config})
      : errorConfig = config ?? ErrorHandlerConfig();

  @override
  void handleError(Object error, [Object? externalStackTrace]) {
    switch (errorConfig.errorHanldeApproach) {
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
