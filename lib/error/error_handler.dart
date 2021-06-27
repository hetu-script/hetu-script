abstract class ErrorHandlerConfig {
  bool get stackTrace;

  int get hetuStackTraceThreshhold;
}

class ErrorHandlerConfigImpl implements ErrorHandlerConfig {
  @override
  final bool stackTrace;

  @override
  final int hetuStackTraceThreshhold;

  const ErrorHandlerConfigImpl(
      {this.stackTrace = true, this.hetuStackTraceThreshhold = 10});
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
