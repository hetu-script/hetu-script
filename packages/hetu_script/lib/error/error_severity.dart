/// The severity of an message.
class ErrorSeverity implements Comparable<ErrorSeverity> {
  /// The severity representing a non-error. This is never used for any error
  /// code, but is useful for clients.
  static const none = ErrorSeverity('NONE', 0, 'none');

  /// The severity representing an informational level analysis issue.
  static const info = ErrorSeverity('INFO', 1, 'info');

  /// The severity representing a warning. Warnings can become errors if the
  /// `-Werror` command line flag is specified.
  static const warning = ErrorSeverity('WARNING', 2, 'warning');

  /// The severity representing an error.
  static const error = ErrorSeverity('ERROR', 3, 'error');

  static const List<ErrorSeverity> values = [none, info, warning, error];

  /// The name of this error code.
  final String name;

  /// The weight value of the error code.
  final int weight;

  /// The name of the severity used when producing readable output.
  final String displayName;

  /// Initialize a newly created severity with the given names.
  const ErrorSeverity(this.name, this.weight, this.displayName);

  bool operator >(ErrorSeverity other) => weight > other.weight;

  bool operator >=(ErrorSeverity other) => weight >= other.weight;

  bool operator <(ErrorSeverity other) => weight < other.weight;

  bool operator <=(ErrorSeverity other) => weight <= other.weight;

  @override
  bool operator ==(Object other) =>
      other is ErrorSeverity && weight == other.weight;

  @override
  int get hashCode => weight;

  @override
  int compareTo(ErrorSeverity other) => weight - other.weight;

  /// Return the severity constant that represents the greatest severity.
  ErrorSeverity max(ErrorSeverity severity) =>
      weight >= severity.weight ? this : severity;

  @override
  String toString() => name;
}
