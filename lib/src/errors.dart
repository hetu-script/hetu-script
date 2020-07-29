import 'common.dart';

class HS_Break {}

class HS_Continue {}

class HS_Error {
  String message;
  int line;
  int column;

  HS_Error(this.message, [this.line, this.column]);

  @override
  String toString() {
    if ((line != null) && (column != null)) {
      return 'Hetu error at [line-$line, column-$column]:\n${message}';
    } else {
      return 'Hetu error:\n${message}';
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

class HSErr_Unsupport extends HS_Error {
  HSErr_Unsupport(String symbol, int line, int column) : super('${HS_Common.ErrorUnsupport} "${symbol}"', line, column);
}

class HSErr_Expected extends HS_Error {
  HSErr_Expected(String expected, String met, int line, int column)
      : super('"${expected}" ${HS_Common.ErrorExpected} "${met}"', line, column);
}

class HSErr_Unexpected extends HS_Error {
  HSErr_Unexpected(String symbol, int line, int column)
      : super('${HS_Common.ErrorUnexpected} "${symbol}"', line, column);
}

class HSErr_Private extends HS_Error {
  HSErr_Private(String symbol, int line, int column) : super('${HS_Common.ErrorPrivate} "${symbol}"', line, column);
}

class HSErr_Undefined extends HS_Error {
  HSErr_Undefined(String symbol, int line, int column) : super('${HS_Common.ErrorUndefined} "${symbol}"', line, column);
}

class HSErr_UndefinedOperator extends HS_Error {
  HSErr_UndefinedOperator(String symbol1, String op, int line, int column)
      : super('${HS_Common.ErrorUndefinedOperator} "${symbol1}" "${op}"', line, column);
}

class HSErr_UndefinedBinaryOperator extends HS_Error {
  HSErr_UndefinedBinaryOperator(String symbol1, String symbol2, String op, int line, int column)
      : super('${HS_Common.ErrorUndefinedOperator} "${symbol1}" "${op}" "${symbol2}"', line, column);
}

class HSErr_Defined extends HS_Error {
  HSErr_Defined(String symbol, int line, int column) : super('"${symbol}" ${HS_Common.ErrorDefined}', line, column);
}

class HSErr_Range extends HS_Error {
  HSErr_Range(int length, int line, int column) : super('${HS_Common.ErrorRange} "${length}"', line, column);
}

class HSErr_InvalidLeftValue extends HS_Error {
  HSErr_InvalidLeftValue(String symbol, int line, int column)
      : super('${HS_Common.ErrorInvalidLeftValue} "${symbol}"', line, column);
}

class HSErr_Callable extends HS_Error {
  HSErr_Callable(String symbol, int line, int column) : super('"${symbol}" ${HS_Common.ErrorCallable}', line, column);
}

class HSErr_UndefinedMember extends HS_Error {
  HSErr_UndefinedMember(String symbol, String type, int line, int column)
      : super('"${symbol}" ${HS_Common.ErrorUndefinedMember} "${type}"', line, column);
}

class HSErr_Condition extends HS_Error {
  HSErr_Condition(int line, int column) : super(HS_Common.ErrorCondition, line, column);
}

class HSErr_MissingFuncDef extends HS_Error {
  HSErr_MissingFuncDef(String symbol, int line, int column)
      : super('${HS_Common.ErrorMissingFuncDef} "${symbol}"', line, column);
}

class HSErr_Get extends HS_Error {
  HSErr_Get(String symbol, int line, int column) : super('"${symbol}" ${HS_Common.ErrorGet}', line, column);
}

class HSErr_SubGet extends HS_Error {
  HSErr_SubGet(String symbol, int line, int column) : super('"${symbol}" ${HS_Common.ErrorSubGet}', line, column);
}

class HSErr_Extends extends HS_Error {
  HSErr_Extends(String symbol, int line, int column) : super('"${symbol}" ${HS_Common.ErrorExtends}', line, column);
}

class HSErr_Setter extends HS_Error {
  HSErr_Setter(int line, int column) : super('${HS_Common.ErrorSetter}', line, column);
}

class HSErr_NullObject extends HS_Error {
  HSErr_NullObject(String symbol, int line, int column)
      : super('"${symbol}" ${HS_Common.ErrorNullObject}', line, column);
}

class HSErr_Type extends HS_Error {
  HSErr_Type(String assign_value, String decl_value, int line, int column)
      : super('${HS_Common.ErrorType1} "${assign_value}" ${HS_Common.ErrorType2} "${decl_value}"', line, column);
}

class HSErr_ArgType extends HS_Error {
  HSErr_ArgType(String assign_value, String decl_value, int line, int column)
      : super('${HS_Common.ErrorArgType1} "${assign_value}" ${HS_Common.ErrorArgType2} "${decl_value}"', line, column);
}

class HSErr_ReturnType extends HS_Error {
  HSErr_ReturnType(String returned_type, String func_name, String decl_return_type, int line, int column)
      : super(
            '"${returned_type}" ${HS_Common.ErrorReturnType2}'
            ' "${func_name}" ${HS_Common.ErrorReturnType3} "${decl_return_type}"',
            line,
            column);
}

class HSErr_Arity extends HS_Error {
  HSErr_Arity(int args_count, int params_count, int line, int column)
      : super('${HS_Common.ErrorArity1} [${args_count}] ${HS_Common.ErrorArity2} [${params_count}]', line, column);
}
