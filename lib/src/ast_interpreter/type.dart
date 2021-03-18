import '../lexicon.dart';

mixin HTType {
  HTTypeId get typeid;
}

class HTTypeId {
  // List<HTType> get inheritances;
  // List<HTType> get compositions;
  final String id;
  final List<HTTypeId> arguments;

  const HTTypeId(this.id, {this.arguments = const []});

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

  bool isA(HTTypeId typeid) {
    var result = false;
    if ((typeid.id == HTLexicon.ANY) || (id == HTLexicon.NULL)) {
      result = true;
    } else {
      if (id == typeid.id) {
        if (arguments.length >= typeid.arguments.length) {
          result = true;
          for (var i = 0; i < typeid.arguments.length; ++i) {
            if (arguments[i].isNotA(typeid.arguments[i])) {
              result = false;
              break;
            }
          }
        } else {
          result = false;
        }
      }
    }
    return result;
  }

  bool isNotA(HTTypeId typeid) => !isA(typeid);
}
