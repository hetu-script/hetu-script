import 'lexicon.dart';
import 'object.dart';

class HTTypeId with HTObject {
  static const ANY = HTTypeId(HTLexicon.ANY);
  static const NULL = HTTypeId(HTLexicon.NULL);
  static const VOID = HTTypeId(HTLexicon.VOID);
  static const CLASS = HTTypeId(HTLexicon.CLASS);
  static const ENUM = HTTypeId(HTLexicon.ENUM);
  static const NAMESPACE = HTTypeId(HTLexicon.NAMESPACE);
  static const type = HTTypeId(HTLexicon.type);
  static const object = HTTypeId(HTLexicon.object);
  static const function = HTTypeId(HTLexicon.function);
  static const unknown = HTTypeId(HTLexicon.unknown);
  static const number = HTTypeId(HTLexicon.number);
  static const boolean = HTTypeId(HTLexicon.boolean);
  static const string = HTTypeId(HTLexicon.string);
  static const list = HTTypeId(HTLexicon.list);
  static const map = HTTypeId(HTLexicon.map);

  @override
  HTTypeId get typeid => HTTypeId.type;

  static String parseBaseTypeId(String typeString) {
    final argsStart = typeString.indexOf(HTLexicon.typesBracketLeft);
    if (argsStart != -1) {
      final id = typeString.substring(0, argsStart);
      return id;
    } else {
      return typeString;
    }
  }

  final String typeName;
  final bool isNullable;
  final List<HTTypeId> typeArgs;

  const HTTypeId(this.typeName,
      {this.isNullable = true, this.typeArgs = const []});

  @override
  String toString() {
    var typename = StringBuffer();
    typename.write(typeName);
    if (typeArgs.isNotEmpty) {
      typename.write('<');
      for (var i = 0; i < typeArgs.length; ++i) {
        typename.write(typeArgs[i]);
        if ((typeArgs.length > 1) && (i != typeArgs.length - 1)) {
          typename.write(', ');
        }
      }
      typename.write('>');
    }
    return typename.toString();
  }

  @override
  bool operator ==(Object other) {
    if (other is! HTTypeId) {
      return false;
    } else {
      return hashCode == other.hashCode;
    }
  }

  @override
  int get hashCode => toString().hashCode;
}

typedef DDD = int Function<T>(int a, int b);

DDD ddd = <T>(int a, int b) {
  return a + b;
};

class HTClassTypeId extends HTTypeId {
  // TOOD:
}

/// [HTFunctionTypeId] is equivalent to Dart's function typedef,
class HTFunctionTypeId extends HTTypeId {
  final List<String> typeParams;
  final List<HTTypeId> paramsTypes; // function(T1 arg1, T2 arg2)
  final HTTypeId returnType;

  const HTFunctionTypeId(
      {this.typeParams = const [],
      this.paramsTypes = const [],
      this.returnType = HTTypeId.ANY})
      : super(HTLexicon.function);

  @override
  String toString() {
    var result = StringBuffer();
    result.write(HTLexicon.function);
    if (typeParams.isNotEmpty) {
      result.write('<');
      for (var i = 0; i < typeParams.length; ++i) {
        result.write(typeParams[i]);
        if ((typeParams.length > 1) && (i != typeParams.length - 1)) {
          result.write(', ');
        }
      }
      result.write('>');
    }

    result.write('(');

    for (final paramType in paramsTypes) {
      result.write(paramType.toString());
      //if (param.initializer != null)
      if (paramsTypes.length > 1) result.write(', ');
    }
    result.write(') -> ' + returnType.toString());
    return result.toString();
  }

  // TODO: 通过重写isA，实现函数的逆变
}
