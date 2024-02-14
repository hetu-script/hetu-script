import '../value/struct/struct.dart';
import '../types.dart';

/// Lexicon used by Hetu
abstract class HTLexicon {
  /// the name of this lexicon.
  String get name;

  String get identifierStartPattern;
  String get identifierPattern;
  String get numberStartPattern;
  String get digitPattern;
  String get numberPattern;
  String get hexNumberPattern;
  String get stringInterpolationPattern;

  /// a character sequence that marked the start of literal hex number.
  String get hexNumberStart;

  /// a character sequence that marked the start of single line comment.
  String get singleLineCommentStart;

  /// a character sequence that marked the start of multiline line comment.
  String get multiLineCommentStart;

  /// a character sequence that marked the end of multiline line comment.
  String get multiLineCommentEnd;

  /// a character sequence that marked the start of documentation comment.
  String get documentationCommentStart;

  /// a character sequence that marked the start of interpolation in strings.
  String get stringInterpolationStart;

  /// a single character that marked the end of interpolation in strings.
  String get stringInterpolationEnd;

  /// a single character that marked the start of escape in strings.
  String get escapeCharacterStart;

  /// escaped characters mapping.
  Map<String, String> get escapeCharacters;

  /// Add end of statement mark if a line ends with 'return'
  /// This is to avoid ambiguity in parser.
  List<String> get autoSemicolonInsertionAtLineEnd => [
        kReturn,
      ];

  /// Add end of statement mark if:
  /// the first line DOES NOT end with `unfinished tokens`, and
  /// the second line starts with one of '{, (, [, ++, --'.
  /// This is to avoid ambiguity in parser.
  List<String> get unfinishedTokens => [
        logicalNot,
        multiply,
        devide,
        modulo,
        add,
        subtract,
        lesser,
        lesserOrEqual,
        greater,
        greaterOrEqual,
        equal,
        notEqual,
        strictEqual,
        strictNotEqual,
        ifNull,
        logicalAnd,
        logicalOr,
        assign,
        assignAdd,
        assignSubtract,
        assignMultiply,
        assignDevide,
        assignIfNull,
        memberGet,
        groupExprStart,
        blockStart,
        enumStart,
        classStart,
        structStart,
        subGetStart,
        listStart,
        externalFunctionTypeDefStart,
        comma,
        constructorInitializationListIndicator,
        namedArgumentValueIndicator,
        typeIndicator,
        structValueIndicator,
        returnTypeIndicator,
        switchBranchIndicator,
        singleLineFunctionIndicator,
        typeListStart,
      ];

  List<String> get autoEndOfStatementMarkInsertionBeforeLineStart => [
        blockStart,
        structStart,
        enumStart,
        classStart,
        functionParameterStart,
        subGetStart,
        preIncrement,
        preDecrement,
      ];

  String get globalObjectId;
  String get globalPrototypeId;

  Set<String> get privatePrefixes;
  String get preferredPrivatePrefix;
  String get internalPrefix;

  bool preferVariantOfMutableKeyword = false;
  bool preferVariantOfFunctionKeyword = false;
  bool preferVariantOfConstructorKeyword = false;
  bool preferVariantOfSwitchKeyword = false;

  String get kAny;
  String get kUnknown;
  String get kVoid;
  String get kNever;

  String get kType;
  // String get kFunction;
  // String get kNamespace;

  Set<String> get builtinIntrinsicTypes => {
        kType,
        ...kFunctions,
        kNamespace,
      };

  String get kBoolean;
  String get kNumber;
  String get kInteger;
  String get kFloat;
  String get kString;

  Set<String> get builtinNominalTypes => {
        kBoolean,
        kNumber,
        kInteger,
        kFloat,
        kString,
      };

  String get kNull;
  String get kTrue;
  String get kFalse;

  String get kMutable =>
      preferVariantOfMutableKeyword ? kMutables.last : kMutables.first;
  Set<String> get kMutables;

  String get kImmutable;
  String get kConst;
  String get kLate;
  String get kDelete;

  Set<String> get destructuringDeclarationMarks => {
        listStart,
        structStart,
      };

  /// Variable declaration keyword
  Set<String> get variableDeclarationKeywords => {
        ...kMutables,
        kImmutable,
        kConst,
        kLate,
      };

  /// Variable declaration keyword
  /// used in for statement's declaration part
  Set<String> get forDeclarationKeywords => {
        ...kMutables,
        kImmutable,
      };

  String get kTypeDef;
  String get kTypeOf;
  String get kDeclTypeof;
  String get kTypeValue;

  String get kImport;
  String get kExport;
  String get kFrom;

  String get kAssert;
  String get kAs;
  String get kNamespace;
  String get kClass;
  String get kEnum;

  String get kFunction =>
      preferVariantOfFunctionKeyword ? kFunctions.last : kFunctions.first;
  Set<String> get kFunctions;

  String get kStruct;
  String get kAlias;
  String get kThis;
  String get kSuper;

  Set<String> get redirectingConstructorCallKeywords => {kThis, kSuper};

  String get kAbstract;
  String get kExternal;
  String get kStatic;
  String get kExtends;
  String get kImplements;
  String get kWith;
  String get kRequired;
  String get kReadonly;

  String get kConstructor => preferVariantOfConstructorKeyword
      ? kConstructors.last
      : kConstructors.first;
  Set<String> get kConstructors;

  String get kNew;
  String get kFactory;
  String get kGet;
  String get kSet;
  String get kAsync;

  String get kAwait;
  String get kBreak;
  String get kContinue;
  String get kReturn;
  String get kFor;
  String get kIn;
  String get kNotIn;
  String get kOf;
  String get kIf;
  String get kElse;
  String get kWhile;
  String get kDo;

  String get kIs;
  String get kIsNot;

  String get kSwitch =>
      preferVariantOfSwitchKeyword ? kSwitchs.last : kSwitchs.first;
  Set<String> get kSwitchs;

  String get kCase;
  String get kDefault;

  String get kTry;
  String get kCatch;
  String get kFinally;
  String get kThrow;

  /// reserved keywords, cannot used as identifier names
  /// DO NOT put puctuations like '_' in this list,
  /// otherwise lexer would not function correctly.
  Set<String> get keywords => {
        kNull,
        ...kMutables,
        kImmutable,
        kLate,
        kConst,
        kDelete,
        kTypeOf,
        kDeclTypeof,
        kTypeValue,
        kClass,
        // kExtends,
        kEnum,
        ...kFunctions,
        kStruct,
        kThis,
        kSuper,
        // kAbstract,
        // kExternal,
        // kStatic,
        // kWith,
        kNew,
        // ...kConstructors,
        // kFactory,
        // kGet,
        // kSet,
        kAsync,
        kAwait,
        kBreak,
        kContinue,
        kReturn,
        kFor,
        kIn,
        kIf,
        kElse,
        kWhile,
        kDo,
        ...kSwitchs,
        kCase,
        kIs,
        kAs,
        // kThrow,
        // kTry,
        // kCatch,
        // kFinally,
      };

  String get indent;

  String get decimalPoint;

  String get variadicArgs;

  String get spreadSyntax;

  String get omittedMark;

  String get everythingMark;

  String get defaultMark;

  String get singleLineFunctionIndicator;

  String get literalFunctionIndicator;

  String get returnTypeIndicator;

  String get switchBranchIndicator;

  String get nullableMemberGet;

  String get memberGet;

  String get nullableSubGet;

  String get subGetStart;

  String get subGetEnd;

  String get nullableFunctionArgumentCall;

  String get functionParameterStart;

  String get functionParameterEnd;

  String get functionNamedParameterStart;

  String get functionNamedParameterEnd;

  String get functionPositionalParameterStart;

  String get functionPositionalParameterEnd;

  String get nullableTypePostfix;

  String get postIncrement;

  String get postDecrement;

  /// postfix operators
  Set<String> get unaryPostfixs => {
        nullableMemberGet,
        memberGet,
        nullableSubGet,
        subGetStart,
        nullableFunctionArgumentCall,
        functionParameterStart,
        postIncrement,
        postDecrement,
      };

  /// prefix operators that modify the value
  Set<String> get unaryPrefixesThatChangeTheValue => {
        preIncrement,
        preDecrement,
      };

  String get logicalNot;

  String get bitwiseNot;

  String get negative;

  String get preIncrement;

  String get preDecrement;

  Set<String> get unaryPrefixes => {
        logicalNot,
        bitwiseNot,
        negative,
        preIncrement,
        preDecrement,
        kTypeOf,
        kDeclTypeof,
        kAwait,
      };

  // Set<String> get unaryPrefixKeywords => {
  //       kTypeOf,
  //       kDeclTypeof,
  //       kAwait,
  //     };

  String get multiply;

  String get devide;

  String get truncatingDevide;

  String get modulo;

  Set<String> get multiplicatives => {
        multiply,
        devide,
        truncatingDevide,
        modulo,
      };

  String get add;

  String get subtract;

  Set<String> get additives => {
        add,
        subtract,
      };

  String get leftShift;

  String get rightShift;

  String get unsignedRightShift;

  Set<String> get shifts => {
        leftShift,
        rightShift,
        unsignedRightShift,
      };

  String get bitwiseAnd;

  String get bitwiseXor;

  String get bitwiseOr;

  String get greater;

  String get greaterOrEqual;

  String get lesser;

  String get lesserOrEqual;

  Set<String> get logicalRelationals => {
        bitwiseAnd,
        bitwiseXor,
        bitwiseOr,
        greater,
        greaterOrEqual,
        lesser,
        lesserOrEqual,
      };

  Set<String> get typeRelationals => {
        kAs,
        kIs,
      };

  Set<String> get setRelationals => {
        kIn,
      };

  String get equal;

  String get notEqual;

  String get strictEqual;

  String get strictNotEqual;

  Set<String> get equalitys => {
        equal,
        notEqual,
        strictEqual,
        strictNotEqual,
      };

  String get logicalAnd;

  String get logicalOr;

  String get ifNull;

  String get ternaryThen;

  String get ternaryElse;

  String get cascade;

  String get nullableCascade;

  String get assign;

  String get assignAdd;

  String get assignSubtract;

  String get assignMultiply;

  String get assignDevide;

  String get assignTruncatingDevide;

  String get assignIfNull;

  String get assignBitwiseAnd;

  String get assignBitwiseOr;

  String get assignBitwiseXor;

  String get assignLeftShift;

  String get assignRightShift;

  String get assignUnsignedRightShift;

  /// assign operators
  Set<String> get assignments => {
        assign,
        assignAdd,
        assignSubtract,
        assignMultiply,
        assignDevide,
        assignTruncatingDevide,
        assignIfNull,
        assignBitwiseAnd,
        assignBitwiseOr,
        assignBitwiseXor,
        assignLeftShift,
        assignRightShift,
        assignUnsignedRightShift,
      };

  String get comma;

  String get constructorInitializationListIndicator;

  String get namedArgumentValueIndicator;

  String get typeIndicator;

  String get structValueIndicator;

  String get endOfStatementMark;

  String get stringStart1;

  String get stringEnd1;

  String get stringStart2;

  String get stringEnd2;

  String get identifierStart;

  String get identifierEnd;

  String get groupExprStart;

  String get groupExprEnd;

  String get blockStart;

  String get blockEnd;

  String get structStart;

  String get structEnd;

  String get enumStart;

  String get enumEnd;

  String get namespaceStart;

  String get namespaceEnd;

  String get classStart;

  String get classEnd;

  String get functionStart;

  String get functionEnd;

  String get listStart;

  String get listEnd;

  String get externalFunctionTypeDefStart;

  String get externalFunctionTypeDefEnd;

  String get typeListStart;

  String get typeListEnd;

  String get importExportListStart;

  String get importExportListEnd;

  /// non-identifers tokens.
  /// DO NOT put '_' or '__' in this list,
  /// otherwise lexer would not function correctly.
  /// because they are treated by lexer as identifiers.
  Set<String> get punctuations => {
        decimalPoint,
        variadicArgs,
        spreadSyntax,
        // omittedMark,
        everythingMark,
        // defaultMark,
        literalFunctionIndicator,
        returnTypeIndicator,
        switchBranchIndicator,
        singleLineFunctionIndicator,
        nullableMemberGet,
        memberGet,
        nullableSubGet,
        nullableFunctionArgumentCall,
        subGetStart,
        subGetEnd,
        functionParameterStart,
        functionParameterEnd,
        functionNamedParameterStart,
        functionNamedParameterEnd,
        functionPositionalParameterStart,
        functionPositionalParameterEnd,
        nullableTypePostfix,
        postIncrement,
        postDecrement,
        logicalNot,
        bitwiseNot,
        negative,
        preIncrement,
        preDecrement,
        multiply,
        devide,
        truncatingDevide,
        modulo,
        add,
        subtract,
        leftShift,
        rightShift,
        unsignedRightShift,
        bitwiseAnd,
        bitwiseXor,
        bitwiseOr,
        greater,
        greaterOrEqual,
        lesser,
        lesserOrEqual,
        equal,
        notEqual,
        strictEqual,
        strictNotEqual,
        logicalOr,
        logicalAnd,
        ifNull,
        ternaryThen,
        ternaryElse,
        cascade,
        nullableCascade,
        assign,
        assignAdd,
        assignSubtract,
        assignMultiply,
        assignDevide,
        assignTruncatingDevide,
        assignIfNull,
        assignBitwiseAnd,
        assignBitwiseOr,
        assignBitwiseXor,
        assignLeftShift,
        assignRightShift,
        assignUnsignedRightShift,
        comma,
        constructorInitializationListIndicator,
        namedArgumentValueIndicator,
        typeIndicator,
        structValueIndicator,
        endOfStatementMark,
        stringStart1,
        stringEnd1,
        stringStart2,
        stringEnd2,
        identifierStart,
        identifierEnd,
        groupExprStart,
        groupExprEnd,
        blockStart,
        blockEnd,
        enumStart,
        enumEnd,
        namespaceStart,
        namespaceEnd,
        classStart,
        classEnd,
        functionStart,
        functionEnd,
        structStart,
        structEnd,
        listStart,
        listEnd,
        externalFunctionTypeDefStart,
        externalFunctionTypeDefEnd,
        typeListStart,
        typeListEnd,
        importExportListStart,
        importExportListEnd,
        // kTypeValue
      };

  /// Marker for group start and end.
  Map<String, String> get groupClosings => {
        stringStart1: stringEnd1,
        stringStart2: stringEnd2,
        identifierStart: identifierEnd,
        groupExprStart: groupExprEnd,
        blockStart: blockEnd,
        enumStart: enumEnd,
        namespaceStart: namespaceEnd,
        classStart: classEnd,
        functionStart: functionEnd,
        structStart: structEnd,
        listStart: listEnd,
        externalFunctionTypeDefStart: externalFunctionTypeDefEnd,
        typeListStart: typeListEnd,
        importExportListStart: importExportListEnd,
      };

  String getBaseTypeId(String typeString) {
    final argsStart = typeString.indexOf(typeListStart);
    if (argsStart != -1) {
      return typeString.substring(0, argsStart);
    } else {
      return typeString;
    }
  }

  bool isPrivate(String? id) {
    if (id == null) return true;
    for (final prefix in privatePrefixes) {
      if (id.startsWith(prefix) && !id.startsWith(internalPrefix)) {
        return true;
      }
    }

    return false;
  }

  var _curIndentCount = 0;

  String _curIndent() {
    final output = StringBuffer();
    var i = _curIndentCount;
    while (i > 0) {
      output.write(indent);
      --i;
    }
    return output.toString();
  }

  /// Print an object to a string.
  String stringify(Object? object, {bool asStringLiteral = false}) {
    final output = StringBuffer();
    if (object is String) {
      if (asStringLiteral) {
        return "'$object'";
      } else {
        return object;
      }
    } else if (object is Iterable) {
      if (object.isEmpty) {
        return '$listStart$listEnd';
      }
      output.writeln(listStart);
      ++_curIndentCount;
      for (var i = 0; i < object.length; ++i) {
        final item = object.elementAt(i);
        output.write(_curIndent());
        final itemString = stringify(item, asStringLiteral: true);
        output.write(itemString);
        if (i < object.length - 1) {
          output.write(comma);
        }
        output.writeln();
      }
      --_curIndentCount;
      output.write(_curIndent());
      output.write(listEnd);
    } else if (object is Map) {
      output.write(structStart);
      final keys = object.keys.toList();
      for (var i = 0; i < keys.length; ++i) {
        final key = keys[i];
        final value = object[key];
        final keyString = stringify(key);
        final valueString = stringify(value);
        output.write('$keyString: $valueString');
        if (i < keys.length - 1) {
          output.write('$comma ');
        }
      }
      output.write(structEnd);
    } else if (object is HTStruct) {
      if (object.isEmpty) {
        output.write('$structStart$structEnd');
      } else {
        final structString = _stringifyStruct(object);
        output.write(structString);
      }
    } else if (object is HTType) {
      final typeString = _stringifyType(object, showTypeKeyword: true);
      output.write(typeString);
    } else {
      output.write(object.toString());
    }
    return output.toString();
  }

  String _stringifyStruct(HTStruct struct,
      {HTStruct? from, bool withBraces = true}) {
    final output = StringBuffer();
    if (withBraces) {
      output.writeln(structStart);
      ++_curIndentCount;
    }
    for (var i = 0; i < struct.length; ++i) {
      final key = struct.keys.elementAt(i);
      if (from != null && from.containsKey(key)) continue;
      if (key.startsWith(internalPrefix)) continue;
      output.write(_curIndent());
      final value = struct[key];
      final valueBuffer = StringBuffer();
      if (value is HTStruct) {
        if (value.isEmpty) {
          valueBuffer.write('$structStart$structEnd');
        } else {
          final content = _stringifyStruct(value);
          // valueBuffer.writeln(codeBlockStart);
          valueBuffer.write(content);
          // valueBuffer.write(_curIndent());
          // valueBuffer.write(codeBlockEnd);
        }
      } else {
        final valueString = stringify(value, asStringLiteral: true);
        valueBuffer.write(valueString);
      }
      output.write('$key$structValueIndicator $valueBuffer');
      if (i < struct.length - 1) {
        output.write(comma);
      }
      output.writeln();
    }
    if (struct.prototype != null && !struct.prototype!.isRootPrototype) {
      final inherits = _stringifyStruct(struct.prototype!,
          from: from ?? struct, withBraces: false);
      output.write(inherits);
    }
    if (withBraces) {
      --_curIndentCount;
      output.write(_curIndent());
      output.write(structEnd);
    }
    return output.toString();
  }

  String _stringifyType(HTType type, {bool showTypeKeyword = false}) {
    final output = StringBuffer();
    if (type is HTFunctionType) {
      if (showTypeKeyword) output.write('$kType ');
      if (type.genericTypeParameters.isNotEmpty) {
        output.write(typeListStart);
        for (var i = 0; i < type.genericTypeParameters.length; ++i) {
          output.write(type.genericTypeParameters[i]);
          if (i < type.genericTypeParameters.length - 1) {
            output.write('$comma ');
          }
        }
        output.write(typeListEnd);
      }
      output.write(functionParameterStart);
      var i = 0;
      var optionalStarted = false;
      var namedStarted = false;
      for (final param in type.parameterTypes) {
        if (param.isVariadic) {
          output.write('$variadicArgs ');
        }
        if (param.isOptional && !optionalStarted) {
          optionalStarted = true;
          output.write(functionPositionalParameterStart);
        } else if (param.isNamed && !namedStarted) {
          namedStarted = true;
          output.write(functionNamedParameterStart);
        }
        final declTypeString = _stringifyType(param.declType);
        if (param.isNamed) {
          output.write('${param.id}: $declTypeString');
        } else {
          output.write(declTypeString);
        }
        if (i < type.parameterTypes.length - 1) {
          output.write('$comma ');
        }
        if (optionalStarted) {
          output.write(functionPositionalParameterEnd);
        } else if (namedStarted) {
          namedStarted = true;
          output.write(functionNamedParameterEnd);
        }
        ++i;
      }
      final returnTypeString =
          type.returnType != null ? _stringifyType(type.returnType!) : kAny;
      output.write(
          '$functionParameterEnd $returnTypeIndicator $returnTypeString');
    } else if (type is HTStructuralType) {
      if (showTypeKeyword) output.write('$kType ');
      if (type.fieldTypes.isEmpty) {
        output.write('$structStart$structEnd');
      } else {
        output.writeln(structStart);
        for (var i = 0; i < type.fieldTypes.length; ++i) {
          final key = type.fieldTypes.keys.elementAt(i);
          output.write('  $key$typeIndicator');
          final fieldTypeString = _stringifyType(type.fieldTypes[key]!);
          output.write(' $fieldTypeString');
          if (i < type.fieldTypes.length - 1) {
            output.write(comma);
          }
          output.writeln();
        }
        output.write(structEnd);
      }
    } else if (type is HTExternalType) {
      if (showTypeKeyword) output.write('$kExternal $kType ');
      output.write('${type.id}');
    } else if (type is HTNominalType) {
      if (showTypeKeyword) output.write('$kType ');
      output.write(type.id);
      if (type.typeArgs.isNotEmpty) {
        output.write(typeListStart);
        for (var i = 0; i < type.typeArgs.length; ++i) {
          output.write(type.typeArgs[i]);
          if ((type.typeArgs.length > 1) && (i != type.typeArgs.length - 1)) {
            output.write('$comma ');
          }
        }
        output.write(typeListEnd);
      }
      if (type.isNullable) {
        output.write(nullableTypePostfix);
      }
    } else {
      output.write(type.id);
    }
    return output.toString();
  }

  // below are language specific ids.

  /// `name` api on enum item.
  String get idEnumItemName;

  /// `values` api.
  String get idCollectionValues;

  /// `contains` api.
  String get idCollectionContains;

  /// `iterator` api on Iterable.
  String get idIterableIterator;

  /// `moveNext()` api on iterator.
  String get idIterableIteratorMoveNext;

  /// `current` api on iterator.
  String get idIterableIteratorCurrent;

  /// `toString()` api on Object & struct object.
  String get idToString;

  /// `bind()` api on function object.
  String get idBind;

  /// `apply()` api on function object.
  String get idApply;

  /// `then()` api on Future object.
  String get idThen;
}
