import 'common.dart';

class HetuBreak {}

abstract class HetuError {
  String message;
  int line;
  int column;

  HetuError(this.message, [this.line, this.column]);

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

class HetuErrorUnexpected extends HetuError {
  HetuErrorUnexpected(String symbol, [int line, int column])
      : super('${Common.ErrorUnexpected} "${symbol}"', line, column);
}

class HetuErrorUndefined extends HetuError {
  HetuErrorUndefined(String symbol, [int line, int column])
      : super('${Common.ErrorUndefined} "${symbol}"', line, column);
}

class HetuErrorUndefinedOperator extends HetuError {
  HetuErrorUndefinedOperator(String symbol1, String op, [int line, int column])
      : super('${Common.ErrorUndefinedOperator} "${symbol1}" "${op}"', line, column);
}

class HetuErrorDefined extends HetuError {
  HetuErrorDefined(String symbol, [int line, int column]) : super('"${symbol}" ${Common.ErrorDefined}', line, column);
}

class HetuErrorRange extends HetuError {
  HetuErrorRange(int length, [int line, int column]) : super('${Common.ErrorRange} "${length}"', line, column);
}

class HetuErrorInvalidLeftValue extends HetuError {
  HetuErrorInvalidLeftValue(String symbol, [int line, int column])
      : super('${Common.ErrorInvalidLeftValue} "${symbol}"', line, column);
}

class HetuErrorCallable extends HetuError {
  HetuErrorCallable(String symbol, [int line, int column]) : super('"${symbol}" ${Common.ErrorCallable}', line, column);
}

class HetuErrorUndefinedMember extends HetuError {
  HetuErrorUndefinedMember(String symbol, String type, [int line, int column])
      : super('"${symbol}" ${Common.ErrorUndefinedMember} "${type}"', line, column);
}

class HetuErrorCondition extends HetuError {
  HetuErrorCondition([int line, int column]) : super(Common.ErrorCondition, line, column);
}

class HetuErrorGet extends HetuError {
  HetuErrorGet(String symbol, [int line, int column]) : super('"${symbol}" ${Common.ErrorGet}', line, column);
}

class HetuErrorExtends extends HetuError {
  HetuErrorExtends(String symbol, [int line, int column]) : super('"${symbol}" ${Common.ErrorExtends}', line, column);
}

class HetuErrorType extends HetuError {
  HetuErrorType(String assign_value, String decl_value, [int line, int column])
      : super('${Common.ErrorType1} "${assign_value}" ${Common.ErrorType2} "${decl_value}"', line, column);
}

class HetuErrorArgType extends HetuError {
  HetuErrorArgType(String assign_value, String decl_value, [int line, int column])
      : super('${Common.ErrorType1} "${assign_value}" ${Common.ErrorType2} "${decl_value}"', line, column);
}

class HetuErrorReturnType extends HetuError {
  HetuErrorReturnType(String returned_type, String func_name, String decl_return_type, [int line, int column])
      : super(
            '${Common.ErrorReturnType1} "${returned_type}" ${Common.ErrorReturnType2}'
            ' "${func_name}" ${Common.ErrorReturnType3} "${decl_return_type}"',
            line,
            column);
}

class HetuErrorArity extends HetuError {
  HetuErrorArity(int args_count, int params_count, [int line, int column])
      : super('${Common.ErrorArity1} "${args_count}" ${Common.ErrorArity2} "${params_count}"', line, column);
}
