import 'environment.dart';

abstract class HT_ErrorLisener {
  void onError(HT_Error error);
}

mixin HT_ErrorController {}

class HT_Break {}

class HT_Continue {}

class HT_Error {
  String message;
  int line;
  int column;
  String fileName;

  HT_Error(this.message, this.line, this.column, this.fileName);

  @override
  String toString() {
    var result = StringBuffer();
    result.write('hetu error:');
    if (fileName != null) {
      result.write(' [file: $fileName]');
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

class HSErr_Unsupport extends HT_Error {
  HSErr_Unsupport(String symbol, int line, int column, String fileName)
      : super('${env.lexicon.errorUnsupport} "${symbol}"', line, column, fileName);
}

class HSErr_Expected extends HT_Error {
  HSErr_Expected(String expected, String met, int line, int column, String fileName)
      : super('"${expected != '\n' ? expected : '\\n'}" ${env.lexicon.errorExpected} "${met != '\n' ? met : '\\n'}"',
            line, column, fileName);
}

class HSErr_Unexpected extends HT_Error {
  HSErr_Unexpected(String symbol, int line, int column, String fileName)
      : super('${env.lexicon.errorUnexpected} "${symbol != '\n' ? symbol : '\\n'}"', line, column, fileName);
}

class HSErr_Private extends HT_Error {
  HSErr_Private(String symbol, int line, int column, String fileName)
      : super('${env.lexicon.errorPrivate} "${symbol}"', line, column, fileName);
}

class HSErr_Initialized extends HT_Error {
  HSErr_Initialized(String symbol, int line, int column, String fileName)
      : super('"${symbol}" ${env.lexicon.errorInitialized}', line, column, fileName);
}

class HSErr_Undefined extends HT_Error {
  HSErr_Undefined(String symbol, int line, int column, String fileName)
      : super('${env.lexicon.errorUndefined} "${symbol}"', line, column, fileName);
}

class HSErr_UndefinedOperator extends HT_Error {
  HSErr_UndefinedOperator(String symbol1, String op, int line, int column, String fileName)
      : super('${env.lexicon.errorUndefinedOperator} "${symbol1}" "${op}"', line, column, fileName);
}

class HSErr_UndefinedBinaryOperator extends HT_Error {
  HSErr_UndefinedBinaryOperator(String symbol1, String symbol2, String op, int line, int column, String fileName)
      : super('${env.lexicon.errorUndefinedOperator} "${symbol1}" "${op}" "${symbol2}"', line, column, fileName);
}

class HSErr_Declared extends HT_Error {
  HSErr_Declared(String symbol, int line, int column, String fileName)
      : super('"${symbol}" ${env.lexicon.errorDeclared}', line, column, fileName);
}

class HSErr_Defined extends HT_Error {
  HSErr_Defined(String symbol, int line, int column, String fileName)
      : super('"${symbol}" ${env.lexicon.errorDefined}', line, column, fileName);
}

class HSErr_Range extends HT_Error {
  HSErr_Range(int length, int line, int column, String fileName)
      : super('${env.lexicon.errorRange} "${length}"', line, column, fileName);
}

class HSErr_InvalidLeftValue extends HT_Error {
  HSErr_InvalidLeftValue(String symbol, int line, int column, String fileName)
      : super('${env.lexicon.errorInvalidLeftValue} "${symbol}"', line, column, fileName);
}

class HSErr_Callable extends HT_Error {
  HSErr_Callable(String symbol, int line, int column, String fileName)
      : super('"${symbol}" ${env.lexicon.errorCallable}', line, column, fileName);
}

class HSErr_UndefinedMember extends HT_Error {
  HSErr_UndefinedMember(String symbol, String type, int line, int column, String fileName)
      : super('"${symbol}" ${env.lexicon.errorUndefinedMember} "${type}"', line, column, fileName);
}

class HSErr_Condition extends HT_Error {
  HSErr_Condition(int line, int column, String fileName) : super(env.lexicon.errorCondition, line, column, fileName);
}

class HSErr_MissingFuncDef extends HT_Error {
  HSErr_MissingFuncDef(String symbol, int line, int column, String fileName)
      : super('${env.lexicon.errorMissingFuncDef} "${symbol}"', line, column, fileName);
}

class HSErr_Get extends HT_Error {
  HSErr_Get(String symbol, int line, int column, String fileName)
      : super('"${symbol}" ${env.lexicon.errorGet}', line, column, fileName);
}

class HSErr_SubGet extends HT_Error {
  HSErr_SubGet(String symbol, int line, int column, String fileName)
      : super('"${symbol}" ${env.lexicon.errorSubGet}', line, column, fileName);
}

class HSErr_Extends extends HT_Error {
  HSErr_Extends(String symbol, int line, int column, String fileName)
      : super('"${symbol}" ${env.lexicon.errorExtends}', line, column, fileName);
}

class HSErr_Setter extends HT_Error {
  HSErr_Setter(int line, int column, String fileName) : super('${env.lexicon.errorSetter}', line, column, fileName);
}

class HSErr_NullObject extends HT_Error {
  HSErr_NullObject(String symbol, int line, int column, String fileName)
      : super('"${symbol}" ${env.lexicon.errorNullObject}', line, column, fileName);
}

class HSErr_Type extends HT_Error {
  HSErr_Type(String symbol, String value_type, String decl_value, int line, int column, String fileName)
      : super(
            '${env.lexicon.errorType1} "${symbol}" ${env.lexicon.errorOfType} "${decl_value}" ${env.lexicon.errorType2} "${value_type}"',
            line,
            column,
            fileName);
}

class HSErr_Mutable extends HT_Error {
  HSErr_Mutable(String symbol, int line, int column, String fileName)
      : super('"${symbol}" ${env.lexicon.errorMutable}', line, column, fileName);
}

class HSErr_NotType extends HT_Error {
  HSErr_NotType(String symbol, int line, int column, String fileName)
      : super('"${symbol}" ${env.lexicon.errorNotType}', line, column, fileName);
}

class HSErr_ArgType extends HT_Error {
  HSErr_ArgType(String symbol, String assign_value, String decl_value, int line, int column, String fileName)
      : super(
            '${env.lexicon.errorArgType1} "${assign_value}" ${env.lexicon.errorOfType} "${assign_value}" ${env.lexicon.errorArgType2} "${decl_value}"',
            line,
            column,
            fileName);
}

class HSErr_ReturnType extends HT_Error {
  HSErr_ReturnType(
      String returned_type, String func_name, String decl_return_type, int line, int column, String fileName)
      : super(
            '"${returned_type}" ${env.lexicon.errorReturnType2}'
            ' "${func_name}" ${env.lexicon.errorReturnType3} "${decl_return_type}"',
            line,
            column,
            fileName);
}

class HSErr_Arity extends HT_Error {
  HSErr_Arity(String symbol, int args_count, int params_count, int line, int column, String fileName)
      : super('${env.lexicon.errorArity1} [${args_count}] ${env.lexicon.errorArity2} [${symbol}] [${params_count}]',
            line, column, fileName);
}
