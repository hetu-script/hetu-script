const kStackTraceDisplayCountLimit = 5;

class ErrorHandlerConfig {
  bool showDartStackTrace;

  bool showHetuStackTrace;

  int stackTraceDisplayCountLimit;

  /// Wether fill in errors with detailed information, e.g. line & column info.
  bool processError;

  ErrorHandlerConfig(
      {this.showDartStackTrace = false,
      this.showHetuStackTrace = false,
      this.stackTraceDisplayCountLimit = kStackTraceDisplayCountLimit,
      this.processError = true});
}

typedef HTErrorHandlerCallback = void Function(Object error,
    {Object? externalStackTrace});

/// Abstract error handler class
abstract class HTErrorHandler {
  ErrorHandlerConfig? get errorConfig;

  // void handleError(Object error, [Object? externalStackTrace]);
}

/// Default error handler implementation
class HTErrorHandlerImpl implements HTErrorHandler {
  @override
  final ErrorHandlerConfig errorConfig;

  List errors = [];

  HTErrorHandlerImpl({ErrorHandlerConfig? config})
      : errorConfig = config ?? ErrorHandlerConfig();
}
