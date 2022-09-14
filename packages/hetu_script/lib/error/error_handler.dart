class ErrorHandlerConfig {
  bool showDartStackTrace;

  bool showHetuStackTrace;

  int stackTraceDisplayCountLimit;

  /// Wether fill in errors with detailed information, e.g. line & column info.
  bool processError;

  ErrorHandlerConfig({
    this.showDartStackTrace = false,
    this.showHetuStackTrace = false,
    this.stackTraceDisplayCountLimit = 5,
    this.processError = true,
  });
}

typedef HTErrorHandlerCallback = void Function(Object error,
    {Object? externalStackTrace});

/// A utility class that stores errors.
class HTErrorHandler {
  final ErrorHandlerConfig errorConfig;

  List errors = [];

  HTErrorHandler({ErrorHandlerConfig? config})
      : errorConfig = config ?? ErrorHandlerConfig();
}
