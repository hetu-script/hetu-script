import 'common.dart';

class HS_Break {}

class HS_Continue {}

class HS_Error {
  String message;
  int line;
  int column;
  String file_name;

  HS_Error(this.message, this.line, this.column, this.file_name);

  @override
  String toString() {
    var result = StringBuffer();
    result.write('Hetu error:');
    if (file_name != null) {
      result.write(' [file: $file_name]');
    }
    if ((line != null) && (column != null)) {
      result.write(' [line: $line, column: $column]');
    }
    result.writeln('\n${message}');
    return result.toString();
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
  HSErr_Unsupport(String symbol, int line, int column, String file_name)
      : super('${HS_Common.ErrorUnsupport} "${symbol}"', line, column, file_name);
}

class HSErr_Expected extends HS_Error {
  HSErr_Expected(String expected, String met, int line, int column, String file_name)
      : super('"${expected}" ${HS_Common.ErrorExpected} "${met}"', line, column, file_name);
}

class HSErr_Unexpected extends HS_Error {
  HSErr_Unexpected(String symbol, int line, int column, String file_name)
      : super('${HS_Common.ErrorUnexpected} "${symbol}"', line, column, file_name);
}

class HSErr_Private extends HS_Error {
  HSErr_Private(String symbol, int line, int column, String file_name)
      : super('${HS_Common.ErrorPrivate} "${symbol}"', line, column, file_name);
}

class HSErr_Undefined extends HS_Error {
  HSErr_Undefined(String symbol, int line, int column, String file_name)
      : super('${HS_Common.ErrorUndefined} "${symbol}"', line, column, file_name);
}

class HSErr_UndefinedOperator extends HS_Error {
  HSErr_UndefinedOperator(String symbol1, String op, int line, int column, String file_name)
      : super('${HS_Common.ErrorUndefinedOperator} "${symbol1}" "${op}"', line, column, file_name);
}

class HSErr_UndefinedBinaryOperator extends HS_Error {
  HSErr_UndefinedBinaryOperator(String symbol1, String symbol2, String op, int line, int column, String file_name)
      : super('${HS_Common.ErrorUndefinedOperator} "${symbol1}" "${op}" "${symbol2}"', line, column, file_name);
}

class HSErr_Defined extends HS_Error {
  HSErr_Defined(String symbol, int line, int column, String file_name)
      : super('"${symbol}" ${HS_Common.ErrorDefined}', line, column, file_name);
}

class HSErr_Range extends HS_Error {
  HSErr_Range(int length, int line, int column, String file_name)
      : super('${HS_Common.ErrorRange} "${length}"', line, column, file_name);
}

class HSErr_InvalidLeftValue extends HS_Error {
  HSErr_InvalidLeftValue(String symbol, int line, int column, String file_name)
      : super('${HS_Common.ErrorInvalidLeftValue} "${symbol}"', line, column, file_name);
}

class HSErr_Callable extends HS_Error {
  HSErr_Callable(String symbol, int line, int column, String file_name)
      : super('"${symbol}" ${HS_Common.ErrorCallable}', line, column, file_name);
}

class HSErr_UndefinedMember extends HS_Error {
  HSErr_UndefinedMember(String symbol, String type, int line, int column, String file_name)
      : super('"${symbol}" ${HS_Common.ErrorUndefinedMember} "${type}"', line, column, file_name);
}

class HSErr_Condition extends HS_Error {
  HSErr_Condition(int line, int column, String file_name) : super(HS_Common.ErrorCondition, line, column, file_name);
}

class HSErr_MissingFuncDef extends HS_Error {
  HSErr_MissingFuncDef(String symbol, int line, int column, String file_name)
      : super('${HS_Common.ErrorMissingFuncDef} "${symbol}"', line, column, file_name);
}

class HSErr_Get extends HS_Error {
  HSErr_Get(String symbol, int line, int column, String file_name)
      : super('"${symbol}" ${HS_Common.ErrorGet}', line, column, file_name);
}

class HSErr_SubGet extends HS_Error {
  HSErr_SubGet(String symbol, int line, int column, String file_name)
      : super('"${symbol}" ${HS_Common.ErrorSubGet}', line, column, file_name);
}

class HSErr_Extends extends HS_Error {
  HSErr_Extends(String symbol, int line, int column, String file_name)
      : super('"${symbol}" ${HS_Common.ErrorExtends}', line, column, file_name);
}

class HSErr_Setter extends HS_Error {
  HSErr_Setter(int line, int column, String file_name) : super('${HS_Common.ErrorSetter}', line, column, file_name);
}

class HSErr_NullObject extends HS_Error {
  HSErr_NullObject(String symbol, int line, int column, String file_name)
      : super('"${symbol}" ${HS_Common.ErrorNullObject}', line, column, file_name);
}

class HSErr_Type extends HS_Error {
  HSErr_Type(String assign_value, String decl_value, int line, int column, String file_name)
      : super('${HS_Common.ErrorType1} "${assign_value}" ${HS_Common.ErrorType2} "${decl_value}"', line, column,
            file_name);
}

class HSErr_ArgType extends HS_Error {
  HSErr_ArgType(String assign_value, String decl_value, int line, int column, String file_name)
      : super('${HS_Common.ErrorArgType1} "${assign_value}" ${HS_Common.ErrorArgType2} "${decl_value}"', line, column,
            file_name);
}

class HSErr_ReturnType extends HS_Error {
  HSErr_ReturnType(
      String returned_type, String func_name, String decl_return_type, int line, int column, String file_name)
      : super(
            '"${returned_type}" ${HS_Common.ErrorReturnType2}'
            ' "${func_name}" ${HS_Common.ErrorReturnType3} "${decl_return_type}"',
            line,
            column,
            file_name);
}

class HSErr_Arity extends HS_Error {
  HSErr_Arity(String symbol, int args_count, int params_count, int line, int column, String file_name)
      : super('${HS_Common.ErrorArity1} [${args_count}] ${HS_Common.ErrorArity2} [${symbol}] [${params_count}]', line,
            column, file_name);
}
