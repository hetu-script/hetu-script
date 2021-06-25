import '../interpreter/abstract_interpreter.dart';
import '../object/object.dart';
import '../type/type.dart';
import '../type/nominal_type.dart';
import '../grammar/semantic.dart';
import '../error/error.dart';
import '../declaration/function/function_declaration.dart';
import '../declaration/class/class.dart';
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
        valueType = HTType(typeString);
      }
    }
  }

  @override
  dynamic memberGet(String field, {bool error = true}) {
    if (externalClass != null) {
      final member = externalClass!.instanceMemberGet(externalObject, field);
      if (member is Function) {
        final getter = '${SemanticNames.getter}$field';
        if (klass!.instanceMembers.containsKey(field)) {
          HTFunctionDeclaration func = klass!.instanceMembers[field]!.value;
          func.externalFunc = member;
          return func;
        } else if (klass!.instanceMembers.containsKey(getter)) {
          HTFunctionDeclaration func = klass!.instanceMembers[getter]!.value;
          func.externalFunc = member;
          return func;
        }
      }
      return member;
    } else {
      if (error) {
        throw HTError.undefined(field);
      }
    }
  }

  @override
  void memberSet(String field, dynamic varValue, {bool error = true}) {
    if (externalClass != null) {
      externalClass!.instanceMemberSet(externalObject, field, varValue);
    } else {
      if (error) {
        throw HTError.unknownTypeName(typeString);
      }
    }
  }
}
