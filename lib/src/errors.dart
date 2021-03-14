import 'lexicon.dart';

class HT_Break {}

class HT_Continue {}

class HT_Error {
  String message;
  int? line;
  int? column;
  String? fileName;

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

class HTErr_Assign extends HT_Error {
  HTErr_Assign(String id, [String? fileName, int? line, int? column])
      : super('${HT_Lexicon.errorAssign} "$id"', fileName, line, column);
}

class HTErr_Unsupport extends HT_Error {
  HTErr_Unsupport(String id, [String? fileName, int? line, int? column])
      : super('${HT_Lexicon.errorUnsupport} "$id"', fileName, line, column);
}

class HTErr_Expected extends HT_Error {
  HTErr_Expected(String expected, String met, [String? fileName, int? line, int? column])
      : super('"${expected != '\n' ? expected : '\\n'}" ${HT_Lexicon.errorExpected} "${met != '\n' ? met : '\\n'}"',
            fileName, line, column);
}

class HTErr_ConstMustBeStatic extends HT_Error {
  HTErr_ConstMustBeStatic(String id, [String? fileName, int? line, int? column])
      : super('${HT_Lexicon.errorConstMustBeStatic}', fileName, line, column);
}

class HTErr_Unexpected extends HT_Error {
  HTErr_Unexpected(String id, [String? fileName, int? line, int? column])
      : super('${HT_Lexicon.errorUnexpected} "${id != '\n' ? id : '\\n'}"', fileName, line, column);
}

class HTErr_PrivateMember extends HT_Error {
  HTErr_PrivateMember(String id, [String? fileName, int? line, int? column])
      : super('${HT_Lexicon.errorPrivateMember} "$id"', fileName, line, column);
}

class HTErr_PrivateDecl extends HT_Error {
  HTErr_PrivateDecl(String id, [String? fileName, int? line, int? column])
      : super('${HT_Lexicon.errorPrivateDecl} "$id"', fileName, line, column);
}

class HTErr_Initialized extends HT_Error {
  HTErr_Initialized(String id, [String? fileName, int? line, int? column])
      : super('"$id" ${HT_Lexicon.errorInitialized}', fileName, line, column);
}

class HTErr_Undefined extends HT_Error {
  HTErr_Undefined(String id, [String? fileName, int? line, int? column])
      : super('${HT_Lexicon.errorUndefined} "$id"', fileName, line, column);
}

class HTErr_UndefinedOperator extends HT_Error {
  HTErr_UndefinedOperator(String id1, String op, [String? fileName, int? line, int? column])
      : super('${HT_Lexicon.errorUndefinedOperator} "$id1" "$op"', fileName, line, column);
}

class HTErr_UndefinedBinaryOperator extends HT_Error {
  HTErr_UndefinedBinaryOperator(String id1, String id2, String op, [String? fileName, int? line, int? column])
      : super('${HT_Lexicon.errorUndefinedOperator} "$id1" "$op" "$id2"', fileName, line, column);
}

class HTErr_Declared extends HT_Error {
  HTErr_Declared(String id, [String? fileName, int? line, int? column])
      : super('"$id" ${HT_Lexicon.errorDeclared}', fileName, line, column);
}

class HTErr_Defined extends HT_Error {
  HTErr_Defined(String id, [String? fileName, int? line, int? column])
      : super('"$id" ${HT_Lexicon.errorDefined}', fileName, line, column);
}

class HTErr_Range extends HT_Error {
  HTErr_Range(int length, [String? fileName, int? line, int? column])
      : super('${HT_Lexicon.errorRange} "$length"', fileName, line, column);
}

class HTErr_InvalidLeftValue extends HT_Error {
  HTErr_InvalidLeftValue(String id, [String? fileName, int? line, int? column])
      : super('${HT_Lexicon.errorInvalidLeftValue} "$id"', fileName, line, column);
}

class HTErr_Callable extends HT_Error {
  HTErr_Callable(String id, [String? fileName, int? line, int? column])
      : super('"$id" ${HT_Lexicon.errorCallable}', fileName, line, column);
}

class HTErr_UndefinedMember extends HT_Error {
  HTErr_UndefinedMember(String id, String type, [String? fileName, int? line, int? column])
      : super('"$id" ${HT_Lexicon.errorUndefinedMember} "$type"', fileName, line, column);
}

class HTErr_Condition extends HT_Error {
  HTErr_Condition([int? line, int? column, String? fileName])
      : super(HT_Lexicon.errorCondition, fileName, line, column);
}

class HTErr_MissingFuncDef extends HT_Error {
  HTErr_MissingFuncDef(String id, [String? fileName, int? line, int? column])
      : super('${HT_Lexicon.errorMissingFuncDef} "$id"', fileName, line, column);
}

class HTErr_Get extends HT_Error {
  HTErr_Get(String id, [String? fileName, int? line, int? column])
      : super('"$id" ${HT_Lexicon.errorGet}', fileName, line, column);
}

class HTErr_SubGet extends HT_Error {
  HTErr_SubGet(String id, [String? fileName, int? line, int? column])
      : super('"$id" ${HT_Lexicon.errorSubGet}', fileName, line, column);
}

class HTErr_Extends extends HT_Error {
  HTErr_Extends(String id, [String? fileName, int? line, int? column])
      : super('"$id" ${HT_Lexicon.errorExtends}', fileName, line, column);
}

class HTErr_Setter extends HT_Error {
  HTErr_Setter([int? line, int? column, String? fileName]) : super('${HT_Lexicon.errorSetter}', fileName, line, column);
}

class HTErr_NullObject extends HT_Error {
  HTErr_NullObject(String id, [String? fileName, int? line, int? column])
      : super('"$id" ${HT_Lexicon.errorNullObject}', fileName, line, column);
}

class HTErr_Type extends HT_Error {
  HTErr_Type(String id, String valueType, String declValue, [String? fileName, int? line, int? column])
      : super(
            '${HT_Lexicon.errorType1} "$id" ${HT_Lexicon.errorOfType} "$declValue" ${HT_Lexicon.errorType2} "$valueType"',
            fileName,
            line,
            column);
}

class HTErr_Immutable extends HT_Error {
  HTErr_Immutable(String id, [String? fileName, int? line, int? column])
      : super('"$id" ${HT_Lexicon.errorImmutable}', fileName, line, column);
}

class HTErr_NotType extends HT_Error {
  HTErr_NotType(String id, [String? fileName, int? line, int? column])
      : super('"$id" ${HT_Lexicon.errorNotType}', fileName, line, column);
}

class HTErr_NotClass extends HT_Error {
  HTErr_NotClass(String id, [String? fileName, int? line, int? column])
      : super('"$id" ${HT_Lexicon.errorNotClass}', fileName, line, column);
}

class HTErr_ArgType extends HT_Error {
  HTErr_ArgType(String id, String assignValue, String declValue, [String? fileName, int? line, int? column])
      : super(
          '${HT_Lexicon.errorArgType1} "$assignValue" ${HT_Lexicon.errorOfType} "$assignValue" ${HT_Lexicon.errorArgType2} "$declValue"',
          fileName,
          line,
          column,
        );
}

class HTErr_ReturnType extends HT_Error {
  HTErr_ReturnType(String returnedType, String funcName, String declReturnType,
      [String? fileName, int? line, int? column])
      : super(
            '"$returnedType" ${HT_Lexicon.errorReturnType2}'
            ' "$funcName" ${HT_Lexicon.errorReturnType3} "$declReturnType"',
            fileName,
            line,
            column);
}

class HTErr_FuncWithoutBody extends HT_Error {
  HTErr_FuncWithoutBody(String funcName, [String? fileName, int? line, int? column])
      : super('$funcName ${HT_Lexicon.errorFuncWithoutBody}', fileName, line, column);
}

class HTErr_Arity extends HT_Error {
  HTErr_Arity(String id, int argsCount, int paramsCount, [String? fileName, int? line, int? column])
      : super('${HT_Lexicon.errorArity1} [$argsCount] ${HT_Lexicon.errorArity2} [$id] [$paramsCount]', fileName, line,
            column);
}

class HTErr_Signature extends HT_Error {
  HTErr_Signature([String? fileName]) : super('${HT_Lexicon.errorSignature}', fileName);
}

class HTErr_Int64Table extends HT_Error {
  HTErr_Int64Table([String? fileName]) : super('${HT_Lexicon.errorInt64Table}', fileName);
}

class HTErr_Float64Table extends HT_Error {
  HTErr_Float64Table([String? fileName]) : super('${HT_Lexicon.errorFloat64Table}', fileName);
}

class HTErr_StringTable extends HT_Error {
  HTErr_StringTable([String? fileName]) : super('${HT_Lexicon.errorStringTable}', fileName);
}
