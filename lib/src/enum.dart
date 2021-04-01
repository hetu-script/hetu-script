import 'type.dart';
import 'object.dart';
import 'lexicon.dart';
import 'errors.dart';
import 'interpreter.dart';
import 'declaration.dart';

class HTEnum with HTDeclaration, HTObject, InterpreterRef {
  @override
  final HTTypeId typeid = HTTypeId.ENUM;

  final Map<String, HTEnumItem> defs;

  final bool isExtern;

  HTEnum(String id, this.defs, Interpreter interpreter, {this.isExtern = false}) {
    this.interpreter = interpreter;
    this.id = id;
  }

  @override
  bool contains(String varName) => defs.containsKey(varName);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    if (!isExtern) {
      if (defs.containsKey(varName)) {
        return defs[varName]!;
      } else if (varName == HTLexicon.values) {
        return defs.values.toList();
      }
    } else {
      final externEnumClass = interpreter.fetchExternalClass(id);
      return externEnumClass.memberGet(varName);
    }

    // TODO: elementAt() 方法

    throw HTErrorUndefined(varName);
  }

  @override
  void memberSet(String varName, dynamic value, {String from = HTLexicon.global}) {
    if (defs.containsKey(varName)) {
      throw HTErrorImmutable(varName);
    }
    throw HTErrorUndefined(varName);
  }
}

class HTEnumItem with HTObject {
  @override
  final HTTypeId typeid;

  final int index;

  final String id;

  @override
  String toString() => '${typeid.id}$id';

  HTEnumItem(this.index, this.id, this.typeid);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'typeid':
        return typeid;
      case 'index':
        return index;
      case 'name':
        return id;
      case 'toString':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const <HTTypeId>[]}) =>
            toString();
      default:
        throw HTErrorUndefinedMember(varName, typeid.toString());
    }
  }
}
