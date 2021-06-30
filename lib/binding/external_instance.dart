import '../interpreter/abstract_interpreter.dart';
import '../object/object.dart';
import '../type/type.dart';
import '../type/nominal_type.dart';
import '../type/external_type.dart';
// import '../grammar/semantic.dart';
import '../error/error.dart';
import '../object/function/function.dart';
import '../object/class/class.dart';
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
      this.externalObject, HTAbstractInterpreter interpreter, this.typeString) {
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
        valueType = HTExternalType(typeString);
      }
    }
  }

  @override
  dynamic memberGet(String field, {bool error = true}) {
    if (externalClass != null) {
      final member = externalClass!.instanceMemberGet(externalObject, field);
      if (member is Function) {
        // final getter = '${SemanticNames.getter}$field';
        // if (klass!.namespace.declarations.containsKey(field)) {
        HTFunction func = klass!.memberGet(field, recursive: false);
        func.externalFunc = member;
        return func;
        // } else if (klass!.namespace.declarations.containsKey(getter)) {
        //   HTFunction func = klass!.namespace.declarations[getter]!.value;
        //   func.externalFunc = member;
        //   return func;
        // }
      } else {
        return member;
      }
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
