abstract class ErrorHandlerConfig {
  bool get hetuStackTrace;

  int get hetuStackTraceThreshhold;

  bool get externalStackTrace;
}

class ErrorHandlerConfigImpl implements ErrorHandlerConfig {
  @override
  final bool externalStackTrace;

  @override
  final bool hetuStackTrace;

  @override
  final int hetuStackTraceThreshhold;

  const ErrorHandlerConfigImpl(
      {this.externalStackTrace = true,
      this.hetuStackTrace = true,
      this.hetuStackTraceThreshhold = 10});
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

  const DefaultErrorHandler(
      {this.errorConfig = const ErrorHandlerConfigImpl()});

  @override
  void handleError(Object error, {Object? externalStackTrace}) {
    throw (error);
  }
}
