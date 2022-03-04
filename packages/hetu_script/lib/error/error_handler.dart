enum ErrorHanldeApproach {
  ingore,
  stdout,
  exception,
  log,
}

const kStackTraceDisplayCountLimit = 5;

abstract class ErrorHandlerConfig {
  factory ErrorHandlerConfig(
      {bool showHetuStackTrace = true,
      bool showDartStackTrace = false,
      int stackTraceDisplayCountLimit = kStackTraceDisplayCountLimit,
      ErrorHanldeApproach errorHanldeApproach =
          ErrorHanldeApproach.exception}) {
    return ErrorHandlerConfigImpl(
        showHetuStackTrace: showHetuStackTrace,
        showDartStackTrace: showDartStackTrace,
        stackTraceDisplayCountLimit: stackTraceDisplayCountLimit,
        errorHanldeApproach: errorHanldeApproach);
  }

  bool get showHetuStackTrace;

  bool get showDartStackTrace;

  int get stackTraceDisplayCountLimit;

  ErrorHanldeApproach get errorHanldeApproach;
}

class ErrorHandlerConfigImpl implements ErrorHandlerConfig {
  @override
  final bool showHetuStackTrace;

  @override
  final bool showDartStackTrace;

  @override
  final int stackTraceDisplayCountLimit;

  @override
  final ErrorHanldeApproach errorHanldeApproach;

  const ErrorHandlerConfigImpl(
      {this.showHetuStackTrace = true,
      this.showDartStackTrace = false,
      this.stackTraceDisplayCountLimit = kStackTraceDisplayCountLimit,
      this.errorHanldeApproach = ErrorHanldeApproach.exception});
}

typedef HTErrorHandlerCallback = void Function(Object error,
    {Object? externalStackTrace});

/// Abstract error handler class
abstract class HTErrorHandler {
  ErrorHandlerConfig? get errorConfig;

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
