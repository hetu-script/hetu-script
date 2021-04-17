import 'package:hetu_script/hetu_script.dart';

import '../interpreter.dart';
import '../object.dart';
import '../type.dart';
import '../lexicon.dart';
import '../errors.dart';

/// Class for external object.
class HTExternalInstance<T> with HTObject, InterpreterRef {
  @override
  late final HTType rtType;

  /// the external object.
  final T externalObject;
  final typeString;
  late final HTExternalClass? externalClass;

  final functions = <String, HTFunction>{};

  /// Create a external class object.
  HTExternalInstance(
      this.externalObject, Interpreter interpreter, this.typeString) {
    this.interpreter = interpreter;
    final id = HTType.parseBaseType(typeString);
    if (interpreter.containsExternalClass(id)) {
      externalClass = interpreter.fetchExternalClass(id);
    } else {
      externalClass = null;
    }

    if (interpreter.global.contains(id)) {
      HTClass klass = interpreter.fetchGlobal(id);
      HTClass? curKlass = klass;
      final extended = <HTType>[];
      while (curKlass != null) {
        // 继承类成员，所有超类的成员都会分别保存
        for (final decl in curKlass.instanceMembers.values) {
          if (decl is HTFunction) {
            if (!functions.containsKey(decl.id)) {
              functions[decl.id] = decl;
            }
          }
        }
        if (curKlass.superClassType != null) {
          extended.add(curKlass.superClassType!);
        }
        curKlass = curKlass.superClass;
      }
      rtType = HTInstanceType(klass.id, extended: extended);
    } else {
      if (externalObject is double) {
        rtType = HTType.float;
      } else if (externalObject is String) {
        rtType = HTType.string;
      } else {
        rtType = HTUnknownType(typeString);
      }
    }
  }

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'runtimeType':
        return rtType;
      case 'toString':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.toString();
      default:
        final member =
            externalClass!.instanceMemberGet(externalObject, varName);
        if (member is Function) {
          final funcDecl = functions[varName]!;
          funcDecl.externalFuncDef = member;
          return funcDecl;
        }
        return member;
    }
  }

  @override
  void memberSet(String varName, dynamic varValue,
      {String from = HTLexicon.global}) {
    if (externalClass != null) {
      externalClass!.instanceMemberSet(externalObject, varName, varValue);
    } else {
      throw HTError.unknownType(typeString);
    }
  }
}
