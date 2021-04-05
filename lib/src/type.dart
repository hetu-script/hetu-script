import 'lexicon.dart';
import 'object.dart';

class HTTypeId with HTObject {
  static const TYPE = HTTypeId(HTLexicon.type);
  static const ANY = HTTypeId(HTLexicon.ANY);
  static const NULL = HTTypeId(HTLexicon.NULL);
  static const VOID = HTTypeId(HTLexicon.VOID);
  static const CLASS = HTTypeId(HTLexicon.CLASS);
  static const ENUM = HTTypeId(HTLexicon.ENUM);
  static const NAMESPACE = HTTypeId(HTLexicon.NAMESPACE);
  static const object = HTTypeId(HTLexicon.object);
  static const function = HTTypeId(HTLexicon.function);
  static const unknown = HTTypeId(HTLexicon.unknown);
  static const number = HTTypeId(HTLexicon.number);
  static const boolean = HTTypeId(HTLexicon.boolean);
  static const string = HTTypeId(HTLexicon.string);
  static const list = HTTypeId(HTLexicon.list);
  static const map = HTTypeId(HTLexicon.map);

  @override
  HTTypeId get typeid => HTTypeId.TYPE;

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
  final List<HTTypeId> typeArguments;

  const HTTypeId(this.typeName,
      {this.isNullable = true, this.typeArguments = const []});

  @override
  String toString() {
    var typename = StringBuffer();
    typename.write(typeName);
    if (typeArguments.isNotEmpty) {
      typename.write('<');
      for (var i = 0; i < typeArguments.length; ++i) {
        typename.write(typeArguments[i]);
        if ((typeArguments.length > 1) && (i != typeArguments.length - 1)) {
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

// TODO: dart 的 typedef 本质就是定义一个 function type
class HTFunctionTypeId extends HTTypeId {
  final HTTypeId returnType;
  final List<HTTypeId> paramsTypes; // function(T1 arg1, T2 arg2)

  const HTFunctionTypeId(
      {this.returnType = HTTypeId.ANY,
      List<HTTypeId> arguments = const [],
      this.paramsTypes = const []})
      : super(HTLexicon.function, typeArguments: arguments);

  @override
  String toString() {
    var result = StringBuffer();
    result.write('$typeName');
    if (typeArguments.isNotEmpty) {
      result.write('<');
      for (var i = 0; i < typeArguments.length; ++i) {
        result.write(typeArguments[i]);
        if ((typeArguments.length > 1) && (i != typeArguments.length - 1)) {
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
    result.write('): ' + returnType.toString());
    return result.toString();
  }

  // TODO: 通过重写isA，实现函数的逆变
}
