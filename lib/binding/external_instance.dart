import '../core/abstract_interpreter.dart';
import '../core/object.dart';
import '../type_system/type.dart';
import '../type_system/value_type.dart';
import '../type_system/nominal_type.dart';
import '../grammar/lexicon.dart';
import '../error/errors.dart';
import '../core/declaration/function_declaration.dart';
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

  late final HTClass? klass;

  /// Create a external class object.
  HTExternalInstance(
      this.externalObject, AbstractInterpreter interpreter, this.typeString) {
    this.interpreter = interpreter;
    final id = HTType.parseBaseType(typeString);
    if (interpreter.containsExternalClass(id)) {
      externalClass = interpreter.fetchExternalClass(id);
    } else {
      externalClass = null;
    }

    if (interpreter.coreNamespace.contains(id)) {
      klass = interpreter.coreNamespace.memberGet(id);
      valueType = HTNominalType(klass!);
    } else {
      klass = null;
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
            final getter = '${HTLexicon.getter}$varName';
            if (klass!.instanceMembers.containsKey(varName)) {
              FunctionDeclaration func = klass!.instanceMembers[varName]!.value;
              func.externalFunc = member;
              return func;
            } else if (klass!.instanceMembers.containsKey(getter)) {
              FunctionDeclaration func = klass!.instanceMembers[getter]!.value;
              func.externalFunc = member;
              return func;
            }
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
