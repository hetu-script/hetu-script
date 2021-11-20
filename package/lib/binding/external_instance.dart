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
  dynamic memberGet(String varName) {
    if (externalClass != null) {
      final member = externalClass!.instanceMemberGet(externalObject, varName);
      if (member is Function) {
        // final getter = '${SemanticNames.getter}$varName';
        // if (klass!.namespace.declarations.containsKey(varName)) {
        HTFunction func = klass!.memberGet(varName, recursive: false);
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
      throw HTError.undefined(varName);
    }
  }

  @override
  void memberSet(String varName, dynamic varValue) {
    if (externalClass != null) {
      externalClass!.instanceMemberSet(externalObject, varName, varValue);
    } else {
      throw HTError.unknownTypeName(typeString);
    }
  }
}
