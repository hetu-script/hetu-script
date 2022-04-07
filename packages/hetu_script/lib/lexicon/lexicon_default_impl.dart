import 'lexicon2.dart';
import '../value/struct/struct.dart';

/// Default lexicon implementation used by Hetu.
class HTDefaultLexicon extends HTLexicon {
  @override
  String get name => r'default';

  @override
  String get identifierStartPattern => r'[_\$\p{L}]';

  @override
  String get identifierPattern => r'[_\$\p{L}0-9]';

  @override
  String get numberStartPattern => r'[\.\d]';

  @override
  String get numberPattern => r'[\.\d]';

  @override
  String get hexNumberPattern => r'[0-9a-fA-F]';

  @override
  String get stringInterpolationPattern => r'\${([^\${}]*)}';

  @override
  String get hexNumberStart => r'0x';

  @override
  String get singleLineCommentStart => r'//';

  @override
  String get multiLineCommentStart => r'/*';

  @override
  String get multiLineCommentEnd => r'*/';

  @override
  String get documentationCommentStart => r'///';

  @override
  String get stringInterpolationStart => r'${';

  @override
  String get stringInterpolationEnd => r'}';

  @override
  String get escapeCharacterStart => r'\';

  @override
  Map<String, String> get escapeCharacters => <String, String>{
        r'\': '\\',
        r"'": "'",
        r'"': '"',
        r'`': '`',
        r'n': '\n',
        r't': '\t',
      };

  @override
  String get globalObjectId => 'object';

  @override
  String get globalPrototypeId => 'prototype';

  @override
  String get programEntryFunctionId => 'main';

  /// _
  @override
  String get privatePrefix => '_';

  /// $
  @override
  String get internalPrefix => r'$';

  @override
  String get typeVoid => 'void';

  @override
  String get typeAny => 'any';

  @override
  String get typeUnknown => 'unknown';

  @override
  String get typeNever => 'never';

  @override
  String get typeFunction => 'function';

  @override
  String get typeBoolean => 'bool';

  @override
  String get typeNumber => 'int';

  @override
  String get typeFloat => 'float';

  @override
  String get typeString => 'str';

  @override
  String get propertyCollectionValues => 'values';

  @override
  String get propertyCollectionContains => 'contains';

  @override
  String get propertyIterableIterator => 'iterator';

  @override
  String get propertyIterableIteratorMoveNext => 'moveNext';

  @override
  String get propertyIterableIteratorCurrent => 'current';

  @override
  String get propertyToString => 'toString';

  @override
  String get kNull => 'null';

  @override
  String get kTrue => 'true';

  @override
  String get kFalse => 'false';

  @override
  String get kVar => 'var';

  @override
  String get kFinal => 'final';

  @override
  String get kLate => 'late';

  @override
  String get kConst => 'const';

  @override
  String get kDelete => 'delete';

  @override
  String get kType => 'type';

  @override
  String get kImport => 'import';

  @override
  String get kExport => 'export';

  @override
  String get kFrom => 'from';

  @override
  String get kAssert => 'assert';

  @override
  String get kTypeof => 'typeof';

  @override
  String get kAs => 'as';

  @override
  String get kNamespace => 'namespace';

  @override
  String get kClass => 'class';

  @override
  String get kEnum => 'enum';

  @override
  String get kFun => 'fun';

  @override
  String get kStruct => 'struct';

  @override
  String get kThis => 'this';

  @override
  String get kSuper => 'super';

  @override
  String get kAbstract => 'abstract';

  @override
  String get kOverride => 'override';

  @override
  String get kExternal => 'external';

  @override
  String get kStatic => 'static';

  @override
  String get kExtends => 'extends';

  @override
  String get kImplements => 'implements';

  @override
  String get kWith => 'with';

  @override
  String get kRequired => 'required';

  @override
  String get kReadonly => 'readonly';

  @override
  String get kConstruct => 'construct';

  @override
  String get kNew => 'new';

  @override
  String get kFactory => 'factory';

  @override
  String get kGet => 'get';

  @override
  String get kSet => 'set';

  @override
  String get kAsync => 'async';

  @override
  String get bind => 'bind';

  @override
  String get apply => 'apply';

  @override
  String get kAwait => 'await';

  @override
  String get kBreak => 'break';

  @override
  String get kContinue => 'continue';

  @override
  String get kReturn => 'return';

  @override
  String get kFor => 'for';

  @override
  String get kIn => 'in';

  @override
  String get kNotIn => 'in!';

  @override
  String get kOf => 'of';

  @override
  String get kIf => 'if';

  @override
  String get kElse => 'else';

  @override
  String get kWhile => 'while';

  @override
  String get kDo => 'do';

  @override
  String get kWhen => 'when';

  @override
  String get kIs => 'is';

  @override
  String get kIsNot => 'is!';

  @override
  String get kTry => 'try';

  @override
  String get kCatch => 'catch';

  @override
  String get kFinally => 'finally';

  @override
  String get kThrow => 'throw';

  @override
  String get indent => '  ';

  /// .
  @override
  String get decimalPoint => '.';

  /// ...
  @override
  String get variadicArgs => '...';

  /// ...
  @override
  String get spreadSyntax => '...';

  /// _
  @override
  String get omittedMark => '_';

  /// ->
  @override
  String get functionReturnTypeIndicator => '->';

  /// ->
  @override
  String get whenBranchIndicator => '->';

  /// =>
  @override
  String get functionSingleLineBodyIndicator => '=>';

  /// ?.
  @override
  String get nullableMemberGet => '?.';

  /// .
  @override
  String get memberGet => '.';

  /// ?[
  @override
  String get nullableSubGet => '?[';

  /// ?(
  @override
  String get nullableFunctionArgumentCall => '?(';

  /// [
  @override
  String get subGetStart => '[';

  /// ]
  @override
  String get subGetEnd => ']';

  /// (
  @override
  String get functionCallArgumentStart => '(';

  /// )
  @override
  String get functionCallArgumentEnd => ')';

  /// ?
  @override
  String get nullableTypePostfix => '?';

  /// ++
  @override
  String get postIncrement => '++';

  /// --
  @override
  String get postDecrement => '--';

  /// !
  @override
  String get logicalNot => '!';

  /// -
  @override
  String get negative => '-';

  /// ++
  @override
  String get preIncrement => '++';

  /// --
  @override
  String get preDecrement => '--';

  /// *
  @override
  String get multiply => '*';

  /// /
  @override
  String get devide => '/';

  /// ~/
  @override
  String get truncatingDevide => '~/';

  /// %'
  @override
  String get modulo => '%';

  /// +
  @override
  String get add => '+';

  /// -
  @override
  String get subtract => '-';

  /// +, -
  @override
  Set<String> get additives => {
        add,
        subtract,
      };

  /// >
  @override
  String get greater => '>';

  /// >=
  @override
  String get greaterOrEqual => '>=';

  /// <
  @override
  String get lesser => '<';

  /// <=
  @override
  String get lesserOrEqual => '<=';

  /// ==
  @override
  String get equal => '==';

  /// !=
  @override
  String get notEqual => '!=';

  /// ??
  @override
  String get ifNull => '??';

  /// ||
  @override
  String get logicalOr => '||';

  /// &&
  @override
  String get logicalAnd => '&&';

  /// ?
  @override
  String get ternaryThen => '?';

  /// :
  @override
  String get ternaryElse => ':';

  /// :
  @override
  String get assign => '=';

  /// +=
  @override
  String get assignAdd => '+=';

  /// -=
  @override
  String get assignSubtract => '-=';

  /// *=
  @override
  String get assignMultiply => '*=';

  /// /=
  @override
  String get assignDevide => '/=';

  /// ~/=
  @override
  String get assignTruncatingDevide => '~/=';

  /// ??=
  @override
  String get assignIfNull => '??=';

  /// ,
  @override
  String get comma => ',';

  /// :
  @override
  String get constructorInitializationListIndicator => ':';

  /// :
  @override
  String get namedArgumentValueIndicator => ':';

  /// :
  @override
  String get typeIndicator => ':';

  /// :
  @override
  String get structValueIndicator => ':';

  /// ;
  @override
  String get endOfStatementMark => ';';

  /// '
  @override
  String get stringStart1 => "'";

  /// '
  @override
  String get stringEnd1 => "'";

  /// "
  @override
  String get stringStart2 => '"';

  /// "
  @override
  String get stringEnd2 => '"';

  /// "
  @override
  String get identifierStart => '`';

  /// "
  @override
  String get identifierEnd => '`';

  /// (
  @override
  String get groupExprStart => '(';

  /// )
  @override
  String get groupExprEnd => ')';

  /// {
  @override
  String get functionBlockStart => '{';

  /// }
  @override
  String get functionBlockEnd => '}';

  /// {
  @override
  String get declarationBlockStart => '{';

  /// }
  @override
  String get declarationBlockEnd => '}';

  /// {
  @override
  String get structStart => '{';

  /// }
  @override
  String get structEnd => '}';

  /// [
  @override
  String get listStart => '[';

  /// ]
  @override
  String get listEnd => ']';

  /// [
  @override
  String get optionalPositionalParameterStart => '[';

  /// ]
  @override
  String get optionalPositionalParameterEnd => ']';

  /// {
  @override
  String get namedParameterStart => '{';

  /// }
  @override
  String get namedParameterEnd => '}';

  /// [
  @override
  String get externalFunctionTypeDefStart => '[';

  /// ]
  @override
  String get externalFunctionTypeDefEnd => ']';

  /// <
  @override
  String get typeParameterStart => '<';

  /// >
  @override
  String get typeParameterEnd => '>';

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

  @override
  String stringify(dynamic object, {bool asStringLiteral = false}) {
    final output = StringBuffer();
    if (object is String) {
      if (asStringLiteral) {
        // if (object.contains("'")) {
        //   final objString = object.replaceAll(r"'", r"\'");
        //   return "'$objString'";
        // } else {
        return "'$object'";
        // }
      } else {
        return object;
      }
    } else if (object is HTStruct) {
      if (object.isEmpty) {
        output.write('$functionBlockStart$functionBlockEnd');
      } else {
        output.writeln(functionBlockStart);
        final structString = stringifyStructMembers(object);
        output.write(structString);
        output.write(_curIndent());
        output.write(functionBlockEnd);
      }
    } else if (object is Iterable) {
      final listString = stringifyList(object);
      output.write(listString);
    } else if (object is Map) {
      output.write(functionBlockStart);
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
      output.write(functionBlockEnd);
    } else {
      output.write(object.toString());
    }
    return output.toString();
  }

  @override
  String stringifyList(Iterable list) {
    if (list.isEmpty) {
      return '$listStart$listEnd';
    }
    final output = StringBuffer();
    output.writeln(listStart);
    ++_curIndentCount;
    for (var i = 0; i < list.length; ++i) {
      final item = list.elementAt(i);
      output.write(_curIndent());
      final itemString = stringify(item, asStringLiteral: true);
      output.write(itemString);
      if (i < list.length - 1) {
        output.write(comma);
      }
      output.writeln();
    }
    --_curIndentCount;
    output.write(_curIndent());
    output.write(listEnd);
    return output.toString();
  }

  @override
  String stringifyStructMembers(HTStruct struct, {HTStruct? from}) {
    final output = StringBuffer();
    ++_curIndentCount;
    for (var i = 0; i < struct.length; ++i) {
      final key = struct.keys.elementAt(i);
      if (key.startsWith(internalPrefix)) {
        continue;
      }
      if (from != null && from != struct) {
        if (from.contains(key)) {
          continue;
        }
      }
      output.write(_curIndent());
      final value = struct[key];
      final valueBuffer = StringBuffer();
      if (value is HTStruct) {
        if (value.isEmpty) {
          valueBuffer.write('$functionBlockStart$functionBlockEnd');
        } else {
          final content = stringifyStructMembers(value, from: from);
          valueBuffer.writeln(functionBlockStart);
          valueBuffer.write(content);
          valueBuffer.write(_curIndent());
          valueBuffer.write(functionBlockEnd);
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
    if (struct.prototype != null && struct.prototype!.id != globalPrototypeId) {
      final inherits = stringifyStructMembers(struct.prototype!, from: struct);
      output.write(inherits);
    }
    --_curIndentCount;
    return output.toString();
  }
}
