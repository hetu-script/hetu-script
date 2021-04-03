import 'type.dart';
import 'object.dart';
import 'lexicon.dart';
import 'errors.dart';
import 'interpreter.dart';
import 'declaration.dart';

/// [HTEnum] is the Dart implementation of the enum declaration in Hetu.
class HTEnum with HTDeclaration, HTObject, InterpreterRef {
  @override
  final HTTypeId typeid = HTTypeId.ENUM;

  final Map<String, HTEnumItem> _enums;

  final bool isExtern;

  HTEnum(String id, this._enums, Interpreter interpreter, {this.isExtern = false}) {
    this.interpreter = interpreter;
    this.id = id;
  }

  @override
  bool contains(String varName) => _enums.containsKey(varName);

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    if (!isExtern) {
      if (_enums.containsKey(varName)) {
        return _enums[varName]!;
      } else if (varName == HTLexicon.values) {
        return _enums.values.toList();
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
    if (_enums.containsKey(varName)) {
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
                List<HTTypeId> typeArgs = const []}) =>
            toString();
      default:
        throw HTErrorUndefinedMember(varName, typeid.toString());
    }
  }
}
