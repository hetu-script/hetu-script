import '../implementation/interpreter.dart';
import '../implementation/object.dart';
import '../implementation/type.dart';
import '../implementation/lexicon.dart';
import '../implementation/errors.dart';
import '../implementation/class.dart';
import '../implementation/function.dart';
import 'external_class.dart';

/// Class for external object.
class HTExternalInstance<T> with HTObject, InterpreterRef {
  @override
  late final HTType objectType;

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
      HTClass klass = interpreter.global.fetch(id);
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
        if (curKlass.extendedType != null) {
          extended.add(curKlass.extendedType!);
        }
        curKlass = curKlass.superClass;
      }
      objectType = HTObjectType(klass.id, extended: extended);
    } else {
      objectType = HTUnknownType(typeString);
    }
  }

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'objectType':
        return objectType;
      case 'toString':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.toString();
      default:
        if (externalClass != null) {
          final member =
              externalClass!.instanceMemberGet(externalObject, varName);
          if (member is Function) {
            final funcDecl = functions[varName]!;
            funcDecl.externalFuncDef = member;
            return funcDecl;
          }
          return member;
        } else {
          throw HTError.undefined(varName);
        }
    }
  }

  @override
  void memberSet(String varName, dynamic varValue,
      {String from = HTLexicon.global}) {
    if (externalClass != null) {
      externalClass!.instanceMemberSet(externalObject, varName, varValue);
    } else {
      throw HTError.unknownTypeName(typeString);
    }
  }
}
