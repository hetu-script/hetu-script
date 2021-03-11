import 'lexicon.dart';

class HT_Break {}

class HT_Continue {}

class HT_Error {
  String message;
  int line;
  int column;
  String fileName;

  HT_Error(this.message, [this.fileName, this.line, this.column]);

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
    result.writeln('\n$message');
    return result.toString();
  }

  static final _warnings = <String>[];

  static void add(String message) => _warnings.add(message);

  static void output() {
    for (final msg in _warnings) {
      print('Warning: $msg');
    }
  }

  static void clear() => _warnings.clear();
}

class HTErr_Unsupport extends HT_Error {
  HTErr_Unsupport(String symbol, [String fileName, int line, int column])
      : super('${HT_Lexicon.errorUnsupport} "$symbol"', fileName, line, column);
}

class HTErr_Expected extends HT_Error {
  HTErr_Expected(String expected, String met, [String fileName, int line, int column])
      : super('"${expected != '\n' ? expected : '\\n'}" ${HT_Lexicon.errorExpected} "${met != '\n' ? met : '\\n'}"',
            fileName, line, column);
}

class HTErr_ConstMustBeStatic extends HT_Error {
  HTErr_ConstMustBeStatic(String symbol, [String fileName, int line, int column])
      : super('${HT_Lexicon.errorConstMustBeStatic}', fileName, line, column);
}

class HTErr_Unexpected extends HT_Error {
  HTErr_Unexpected(String symbol, [String fileName, int line, int column])
      : super('${HT_Lexicon.errorUnexpected} "${symbol != '\n' ? symbol : '\\n'}"', fileName, line, column);
}

class HTErr_PrivateMember extends HT_Error {
  HTErr_PrivateMember(String symbol, [String fileName, int line, int column])
      : super('${HT_Lexicon.errorPrivateMember} "$symbol"', fileName, line, column);
}

class HTErr_PrivateDecl extends HT_Error {
  HTErr_PrivateDecl(String symbol, [String fileName, int line, int column])
      : super('${HT_Lexicon.errorPrivateDecl} "$symbol"', fileName, line, column);
}

class HTErr_Initialized extends HT_Error {
  HTErr_Initialized(String symbol, [String fileName, int line, int column])
      : super('"$symbol" ${HT_Lexicon.errorInitialized}', fileName, line, column);
}

class HTErr_Undefined extends HT_Error {
  HTErr_Undefined(String symbol, [String fileName, int line, int column])
      : super('${HT_Lexicon.errorUndefined} "$symbol"', fileName, line, column);
}

class HTErr_UndefinedOperator extends HT_Error {
  HTErr_UndefinedOperator(String symbol1, String op, [String fileName, int line, int column])
      : super('${HT_Lexicon.errorUndefinedOperator} "$symbol1" "$op"', fileName, line, column);
}

class HTErr_UndefinedBinaryOperator extends HT_Error {
  HTErr_UndefinedBinaryOperator(String symbol1, String symbol2, String op, [String fileName, int line, int column])
      : super('${HT_Lexicon.errorUndefinedOperator} "$symbol1" "$op" "$symbol2"', fileName, line, column);
}

class HTErr_Declared extends HT_Error {
  HTErr_Declared(String symbol, [String fileName, int line, int column])
      : super('"$symbol" ${HT_Lexicon.errorDeclared}', fileName, line, column);
}

class HTErr_Defined extends HT_Error {
  HTErr_Defined(String symbol, [String fileName, int line, int column])
      : super('"$symbol" ${HT_Lexicon.errorDefined}', fileName, line, column);
}

class HTErr_Range extends HT_Error {
  HTErr_Range(int length, [String fileName, int line, int column])
      : super('${HT_Lexicon.errorRange} "$length"', fileName, line, column);
}

class HTErr_InvalidLeftValue extends HT_Error {
  HTErr_InvalidLeftValue(String symbol, [String fileName, int line, int column])
      : super('${HT_Lexicon.errorInvalidLeftValue} "$symbol"', fileName, line, column);
}

class HTErr_Callable extends HT_Error {
  HTErr_Callable(String symbol, [String fileName, int line, int column])
      : super('"$symbol" ${HT_Lexicon.errorCallable}', fileName, line, column);
}

class HTErr_UndefinedMember extends HT_Error {
  HTErr_UndefinedMember(String symbol, String type, [String fileName, int line, int column])
      : super('"$symbol" ${HT_Lexicon.errorUndefinedMember} "$type"', fileName, line, column);
}

class HTErr_Condition extends HT_Error {
  HTErr_Condition(int line, int column, String fileName) : super(HT_Lexicon.errorCondition, fileName, line, column);
}

class HTErr_MissingFuncDef extends HT_Error {
  HTErr_MissingFuncDef(String symbol, [String fileName, int line, int column])
      : super('${HT_Lexicon.errorMissingFuncDef} "$symbol"', fileName, line, column);
}

class HTErr_Get extends HT_Error {
  HTErr_Get(String symbol, [String fileName, int line, int column])
      : super('"$symbol" ${HT_Lexicon.errorGet}', fileName, line, column);
}

class HTErr_SubGet extends HT_Error {
  HTErr_SubGet(String symbol, [String fileName, int line, int column])
      : super('"$symbol" ${HT_Lexicon.errorSubGet}', fileName, line, column);
}

class HTErr_Extends extends HT_Error {
  HTErr_Extends(String symbol, [String fileName, int line, int column])
      : super('"$symbol" ${HT_Lexicon.errorExtends}', fileName, line, column);
}

class HTErr_Setter extends HT_Error {
  HTErr_Setter(int line, int column, String fileName) : super('${HT_Lexicon.errorSetter}', fileName, line, column);
}

class HTErr_NullObject extends HT_Error {
  HTErr_NullObject(String symbol, [String fileName, int line, int column])
      : super('"$symbol" ${HT_Lexicon.errorNullObject}', fileName, line, column);
}

class HTErr_Type extends HT_Error {
  HTErr_Type(String symbol, String value_type, String decl_value, [String fileName, int line, int column])
      : super(
            '${HT_Lexicon.errorType1} "$symbol" ${HT_Lexicon.errorOfType} "$decl_value" ${HT_Lexicon.errorType2} "$value_type"',
            fileName,
            line,
            column);
}

class HTErr_Immutable extends HT_Error {
  HTErr_Immutable(String symbol, [String fileName, int line, int column])
      : super('"$symbol" ${HT_Lexicon.errorImmutable}', fileName, line, column);
}

class HTErr_NotType extends HT_Error {
  HTErr_NotType(String symbol, [String fileName, int line, int column])
      : super('"$symbol" ${HT_Lexicon.errorNotType}', fileName, line, column);
}

class HTErr_NotClass extends HT_Error {
  HTErr_NotClass(String symbol, [String fileName, int line, int column])
      : super('"$symbol" ${HT_Lexicon.errorNotClass}', fileName, line, column);
}

class HTErr_ArgType extends HT_Error {
  HTErr_ArgType(String symbol, String assign_value, String decl_value, [String fileName, int line, int column])
      : super(
          '${HT_Lexicon.errorArgType1} "$assign_value" ${HT_Lexicon.errorOfType} "$assign_value" ${HT_Lexicon.errorArgType2} "$decl_value"',
          fileName,
          line,
          column,
        );
}

class HTErr_ReturnType extends HT_Error {
  HTErr_ReturnType(String returned_type, String func_name, String decl_return_type,
      [String fileName, int line, int column])
      : super(
            '"$returned_type" ${HT_Lexicon.errorReturnType2}'
            ' "$func_name" ${HT_Lexicon.errorReturnType3} "$decl_return_type"',
            fileName,
            line,
            column);
}

class HTErr_FuncWithoutBody extends HT_Error {
  HTErr_FuncWithoutBody(String func_name, [String fileName, int line, int column])
      : super('$func_name ${HT_Lexicon.errorFuncWithoutBody}', fileName, line, column);
}

class HTErr_Arity extends HT_Error {
  HTErr_Arity(String symbol, int args_count, int params_count, [String fileName, int line, int column])
      : super('${HT_Lexicon.errorArity1} [$args_count] ${HT_Lexicon.errorArity2} [$symbol] [$params_count]', fileName,
            line, column);
}
