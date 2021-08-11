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
        showDartStackTrace: stackTrace,
        hetuStackTraceDisplayCountLimit: hetuStackTraceThreshhold,
        errorHanldeApproach: approach);
  }

  bool get showDartStackTrace;

  int get hetuStackTraceDisplayCountLimit;

  ErrorHanldeApproach get errorHanldeApproach;
}

class ErrorHandlerConfigImpl implements ErrorHandlerConfig {
  @override
  final bool showDartStackTrace;

  @override
  final int hetuStackTraceDisplayCountLimit;

  @override
  final ErrorHanldeApproach errorHanldeApproach;

  const ErrorHandlerConfigImpl(
      {this.showDartStackTrace = true,
      this.hetuStackTraceDisplayCountLimit = 10,
      this.errorHanldeApproach = ErrorHanldeApproach.exception});
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
