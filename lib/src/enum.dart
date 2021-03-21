import 'type.dart';
import 'object.dart';
import 'lexicon.dart';
import 'errors.dart';
import 'interpreter.dart';

class HTEnum extends HTObject with InterpreterRef {
  @override
  final HTTypeId typeid = HTTypeId.ENUM;

  final String id;

  final Map<String, HTEnumItem> defs;

  final bool isExtern;

  HTEnum(this.id, this.defs, HTInterpreter interpreter, {this.isExtern = false}) {
    this.interpreter = interpreter;
  }

  @override
  bool contains(String varName) => defs.containsKey(varName);

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    if (!isExtern) {
      if (defs.containsKey(varName)) {
        return defs[varName]!;
      } else if (varName == HTLexicon.values) {
        return defs.values.toList();
      }
    } else {
      final externEnumClass = interpreter.fetchExternalClass(id);
      return externEnumClass.fetch(varName);
    }

    // TODO: elementAt() 方法

    throw HTErrorUndefined(varName);
  }

  @override
  void assign(String varName, dynamic value, {String from = HTLexicon.global}) {
    if (defs.containsKey(varName)) {
      throw HTErrorImmutable(varName);
    }
    throw HTErrorUndefined(varName);
  }
}

class HTEnumItem extends HTObject {
  @override
  final HTTypeId typeid;

  final int index;

  final String id;

  @override
  String toString() => '${typeid.id}.$id';

  HTEnumItem(this.index, this.id, this.typeid);

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'typeid':
        return typeid;
      case 'index':
        return index;
      case 'toString':
        return (List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) => toString();
      default:
        throw HTErrorUndefinedMember(varName, typeid.toString());
    }
  }
}
