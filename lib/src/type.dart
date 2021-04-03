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

  final String name;
  final bool isNullable;
  final List<HTTypeId> arguments;

  const HTTypeId(this.name, {this.isNullable = true, this.arguments = const []});

  @override
  String toString() {
    var typename = StringBuffer();
    typename.write(name);
    if (arguments.isNotEmpty) {
      typename.write('<');
      for (var i = 0; i < arguments.length; ++i) {
        typename.write(arguments[i]);
        if ((arguments.length > 1) && (i != arguments.length - 1)) typename.write(', ');
      }
      typename.write('>');
    }
    return typename.toString();
  }
}

// TODO: dart 的 typedef 本质就是定义一个 function type
class HTFunctionTypeId extends HTTypeId {
  final HTTypeId returnType;
  final List<HTTypeId> paramsTypes; // function(T1 arg1, T2 arg2)

  const HTFunctionTypeId(
      {this.returnType = HTTypeId.ANY, List<HTTypeId> arguments = const [], this.paramsTypes = const []})
      : super(HTLexicon.function, arguments: arguments);

  @override
  String toString() {
    var result = StringBuffer();
    result.write('$name');
    if (arguments.isNotEmpty) {
      result.write('<');
      for (var i = 0; i < arguments.length; ++i) {
        result.write(arguments[i]);
        if ((arguments.length > 1) && (i != arguments.length - 1)) result.write(', ');
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
