import 'lexicon.dart';

mixin HTType {
  HTTypeId get typeid;
}

class HTTypeId {
  static const ANY = HTTypeId(HTLexicon.ANY);
  static const NULL = HTTypeId(HTLexicon.NULL);
  static const VOID = HTTypeId(HTLexicon.VOID);
  static const CLASS = HTTypeId(HTLexicon.CLASS);
  static const ENUM = HTTypeId(HTLexicon.ENUM);
  static const namespace = HTTypeId(HTLexicon.NAMESPACE);
  static const function = HTTypeId(HTLexicon.function);
  static const unknown = HTTypeId(HTLexicon.unknown);
  static const number = HTTypeId(HTLexicon.number);
  static const boolean = HTTypeId(HTLexicon.boolean);
  static const string = HTTypeId(HTLexicon.string);
  static const list = HTTypeId(HTLexicon.list);
  static const map = HTTypeId(HTLexicon.map);

  // List<HTType> get inheritances;
  // List<HTType> get compositions;
  final String id;
  final List<HTTypeId> arguments;

  const HTTypeId(this.id, {this.arguments = const []});

  @override
  String toString() {
    var typename = StringBuffer();
    typename.write(id);
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

  bool isA(HTTypeId? typeid) {
    var result = true;
    if (typeid != null && typeid.id != HTLexicon.ANY) {
      if (id == typeid.id) {
        if (arguments.length >= typeid.arguments.length) {
          for (var i = 0; i < typeid.arguments.length; ++i) {
            if (arguments[i].isNotA(typeid.arguments[i])) {
              result = false;
              break;
            }
          }
        } else {
          result = false;
        }
      } else {
        result = false;
      }
    }
    return result;
  }

  bool isNotA(HTTypeId? typeid) => !isA(typeid);
}

class HTFunctionTypeId extends HTTypeId {
  final HTTypeId returnType;
  final List<HTTypeId?> paramsTypes;

  HTFunctionTypeId(this.returnType, {List<HTTypeId> arguments = const [], this.paramsTypes = const []})
      : super(HTLexicon.function, arguments: arguments);

  @override
  String toString() {
    var result = StringBuffer();
    result.write('$id');
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
      result.write(paramType != null ? paramType.id : HTLexicon.ANY);
      //if (param.initializer != null)
      if (paramsTypes.length > 1) result.write(', ');
    }
    result.write('): ' + returnType.toString());
    return result.toString();
  }
}
