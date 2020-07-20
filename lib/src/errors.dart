import 'constants.dart';

class HetuBreak {}

abstract class HetuError {
  String message;
  int line;
  int column;

  HetuError(this.message, {this.line, this.column});

  @override
  String toString() {
    if ((line != null) && (column != null)) {
      return '${message} [${line}-${column}]';
    } else {
      return '${message}';
    }
  }

  static final _warnings = <String>[];

  static void add(String message) => _warnings.add(message);

  static void output() {
    for (var msg in _warnings) {
      print('Warning: $msg');
    }
  }

  static void clear() => _warnings.clear();
}

class HetuErrorRange extends HetuError {
  HetuErrorRange(int length) : super('${Constants.ErrorRange} "${length}"');
}

class HetuErrorType extends HetuError {
  HetuErrorType(String assign_value, String decl_value)
      : super('${Constants.ErrorType1} "${assign_value}" ${Constants.ErrorType2} "${decl_value}"');
}

class HetuErrorReturnType extends HetuError {
  HetuErrorReturnType(String returned_type, String func_name, String decl_return_type)
      : super(
            '${Constants.ErrorReturnType1} "${returned_type}" ${Constants.ErrorReturnType2} "${func_name}" ${Constants.ErrorReturnType3} "${decl_return_type}"');
}

class HetuErrorUndefined extends HetuError {
  HetuErrorUndefined(String symbol) : super('${Constants.ErrorUndefined} "${symbol}"');
}

class HetuErrorDefined extends HetuError {
  HetuErrorDefined(String symbol) : super('${Constants.ErrorDefined1} "${symbol}" ${Constants.ErrorDefined2}');
}

class HetuErrorUndefinedMember extends HetuError {
  HetuErrorUndefinedMember(String symbol, String type)
      : super('${Constants.ErrorUndefinedMember1} "${symbol}" ${Constants.ErrorUndefinedMember2} "${type}"');
}
