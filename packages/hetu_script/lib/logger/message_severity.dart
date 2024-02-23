/// The severity of an message.
class MessageSeverity implements Comparable<MessageSeverity> {
  /// The severity representing a non-error. This is never used for any error
  /// code, but is useful for clients.
  static const none = MessageSeverity('NONE', 0, 'none');

  /// The severity representing an debug message.
  static const debug = MessageSeverity('DEBUG', 1, 'debug');

  /// The severity representing an informational level analysis issue.
  static const info = MessageSeverity('INFO', 2, 'info');

  /// The severity representing a warning.
  static const warn = MessageSeverity('WARN', 3, 'warn');

  /// The severity representing an error.
  static const error = MessageSeverity('ERROR', 4, 'error');

  static const List<MessageSeverity> values = [none, debug, info, warn, error];

  static MessageSeverity of(String name) {
    switch (name) {
      case 'none':
        return MessageSeverity.none;
      case 'debug':
        return MessageSeverity.debug;
      case 'info':
        return MessageSeverity.info;
      case 'warn':
        return MessageSeverity.warn;
      case 'error':
        return MessageSeverity.error;
      default:
        throw 'Unrecognized message severity name: [$name]';
    }
  }

  /// The name of this error code.
  final String name;

  /// The weight value of the error code.
  final int weight;

  /// The name of the severity used when producing readable output.
  final String displayName;

  /// Initialize a newly created severity with the given names.
  const MessageSeverity(this.name, this.weight, this.displayName);

  bool operator >(MessageSeverity other) => weight > other.weight;

  bool operator >=(MessageSeverity other) => weight >= other.weight;

  bool operator <(MessageSeverity other) => weight < other.weight;

  bool operator <=(MessageSeverity other) => weight <= other.weight;

  @override
  bool operator ==(Object other) =>
      other is MessageSeverity && weight == other.weight;

  @override
  int get hashCode => weight;

  @override
  int compareTo(MessageSeverity other) => weight - other.weight;

  /// Return the severity constant that represents the greatest severity.
  MessageSeverity max(MessageSeverity severity) =>
      weight >= severity.weight ? this : severity;

  @override
  String toString() => name;
}
