import '../value/object.dart';
import '../type/type.dart';
import '../type/nominal.dart';
import '../type/external.dart';
// import '../grammar/HTLocale.current.dart';
import '../error/error.dart';
import '../value/function/function.dart';
import '../value/class/class.dart';
import 'external_class.dart';
// import '../value/external_enum/external_enum.dart';
import '../interpreter/interpreter.dart';

/// Class for external object.
class HTExternalInstance<T> with HTObject, InterpreterRef {
  @override
  late final HTType valueType;

  /// the external object.
  final T externalObject;
  final String typeString;
  late final HTExternalClass? externalClass;

  HTClass? klass;

  // HTExternalEnum? enumClass;

  /// Create a external class object.
  HTExternalInstance(
      this.externalObject, HTInterpreter interpreter, this.typeString) {
    this.interpreter = interpreter;
    final id = interpreter.lexicon.getBaseTypeId(typeString);
    if (interpreter.containsExternalClass(id)) {
      externalClass = interpreter.fetchExternalClass(id);
    } else {
      externalClass = null;
    }

    klass = interpreter.currentNamespace
        .memberGet(id, isRecursive: true, ignoreUndefined: true);
    // else if (def is HTExternalEnum) {
    //   enumClass = def;
    // }
    if (klass != null) {
      valueType = HTNominalType(klass: klass!);
    } else {
      valueType = HTExternalType(typeString);
    }
  }

  @override
  dynamic memberGet(String id,
      {String? from, bool isRecursive = false, bool ignoreUndefined = false}) {
    if (externalClass != null) {
      dynamic member = externalClass!.instanceMemberGet(externalObject, id);
      if (member is Function) {
        HTClass? currentKlass = klass!;
        HTFunction? decl;
        while (decl == null && currentKlass != null) {
          decl = currentKlass.memberGet(id, ignoreUndefined: true);
          currentKlass = currentKlass.superClass;
        }
        assert(decl != null,
            'Could not find hetu declaration on external id: $typeString.$id');
        decl = decl!.clone();
        // Assign the value as if we are doing decl.resolve() here.
        decl.externalFunc = member;
        decl.instance = externalObject;
        return decl;
      } else {
        return member;
      }
    }
    if (!ignoreUndefined) {
      throw HTError.undefined(id);
    }
  }

  @override
  void memberSet(String id, dynamic value,
      {String? from, bool defineIfAbsent = false}) {
    if (externalClass != null) {
      externalClass!.instanceMemberSet(externalObject, id, value);
    } else {
      throw HTError.unknownExternalTypeName(typeString);
    }
  }

  String help() {
    final buffer = StringBuffer();
    buffer.writeln('external object: $typeString');
    if (klass != null) {
      buffer.write(klass!.help());
    }
    return buffer.toString();
  }
}
