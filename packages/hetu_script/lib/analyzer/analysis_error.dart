import '../error/error.dart';
import '../error/error_severity.dart';
import 'diagnostic.dart';
import '../locale/locale.dart';

class HTAnalysisError implements HTError {
  @override
  final ErrorCode code;

  @override
  String get name => code.toString().split('.').last;

  @override
  final ErrorType type;

  @override
  ErrorSeverity get severity => type.severity;

  @override
  final String? message;

  @override
  final String? extra;

  @override
  final String? correction;

  @override
  final String filename;

  @override
  final int line;

  @override
  final int column;

  @override
  final int offset;

  @override
  final int length;

  final List<HTDiagnosticMessage> contextMessages;

  HTAnalysisError(this.code, this.type,
      {this.message,
      this.extra,
      List<String> interpolations = const [],
      this.correction,
      required this.filename,
      required this.line,
      required this.column,
      this.offset = 0,
      this.length = 0,
      this.contextMessages = const []});

  @override
  String toString() {
    final output = StringBuffer();
    output.writeln("$message (at [$filename:$line:$column])");
    return output.toString();
  }

  HTAnalysisError.fromError(HTError error,
      {List<HTDiagnosticMessage> contextMessages = const []})
      : this(error.code, error.type,
            message: error.message,
            correction: error.correction,
            filename: error.filename!,
            line: error.line!,
            column: error.column!,
            offset: error.offset!,
            length: error.length!,
            contextMessages: contextMessages);

  HTAnalysisError.constValue(
      {String? extra,
      String? correction,
      required String filename,
      required int line,
      required int column,
      required int offset,
      required int length})
      : this(ErrorCode.constValue, ErrorType.staticWarning,
            message: HTLocale.current.errorConstValue,
            extra: extra,
            correction: correction,
            filename: filename,
            line: line,
            column: column,
            offset: offset,
            length: length);
}
