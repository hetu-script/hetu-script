import '../core/abstract_interpreter.dart';
import '../core/object.dart';
import '../type_system/type.dart';
import '../type_system/value_type.dart';
import '../type_system/nominal_type.dart';
import '../grammar/lexicon.dart';
import '../error/errors.dart';
import '../interpreter/function/funciton.dart';
import '../interpreter/class/class.dart';
import 'external_class.dart';

/// Class for external object.
class HTExternalInstance<T> with HTObject, InterpreterRef {
  @override
  late final HTValueType valueType;

  /// the external object.
  final T externalObject;
  final String typeString;
  late final HTExternalClass? externalClass;

  final functions = <String, HTFunction>{};

  /// Create a external class object.
  HTExternalInstance(
      this.externalObject, HTInterpreter interpreter, this.typeString) {
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
      // final extended = <HTType>[];
      while (curKlass != null) {
        // 继承类成员，所有超类的成员都会分别保存
        for (final decl in curKlass.instanceMembers.values) {
          final value = decl.value;
          if (value is HTFunction) {
            functions[decl.id] = value;
          }
        }
        // if (curKlass.extendedType != null) {
        //   extended.add(curKlass.extendedType!);
        // }
        curKlass = curKlass.superClass;
      }
      valueType = HTNominalType(klass);
    } else {
      valueType = HTExternalType(typeString);
    }
  }

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'valueType':
        return valueType;
      case 'toString':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            externalObject.toString();
      default:
        if (externalClass != null) {
          final member =
              externalClass!.instanceMemberGet(externalObject, varName);
          if (member is Function) {
            final func = functions[varName]!;
            func.externalFunc = member;
            return func;
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
