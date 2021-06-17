import '../interpreter/abstract_interpreter.dart';
import '../element/object.dart';
import '../type/type.dart';
import '../type/nominal_type.dart';
import '../grammar/semantic.dart';
import '../error/error.dart';
import '../element/function_declaration.dart';
import '../element/class/class.dart';
import 'external_class.dart';

/// Class for external object.
class HTExternalInstance<T> with HTObject, InterpreterRef {
  @override
  late final HTType valueType;

  /// the external object.
  final T externalObject;
  final String typeString;
  late final HTExternalClass? externalClass;

  HTClass? klass;

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

    try {
      klass = interpreter.curNamespace.memberGet(id);
    } finally {
      if (klass != null) {
        valueType = HTNominalType(klass!);
      } else {
        valueType = HTType(typeString, interpreter.curModuleFullName,
            interpreter.curLibraryName);
      }
    }
  }

  @override
  dynamic memberGet(String varName,
      {String from = SemanticNames.global, bool error = true}) {
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
            final getter = '${SemanticNames.getter}$varName';
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
          if (error) {
            throw HTError.undefined(varName);
          }
        }
    }
  }

  @override
  void memberSet(String varName, dynamic varValue,
      {String from = SemanticNames.global}) {
    if (externalClass != null) {
      externalClass!.instanceMemberSet(externalObject, varName, varValue);
    } else {
      throw HTError.unknownTypeName(typeString);
    }
  }
}
