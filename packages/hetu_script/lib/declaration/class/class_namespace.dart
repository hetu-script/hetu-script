import '../../error/error.dart';
import '../../grammar/semantic.dart';
import '../../source/source.dart';
import '../../value/function/function.dart';
import '../namespace/namespace.dart';

/// A implementation of [HTNamespace] for [HTClass].
/// For interpreter searching for symbols within static methods.
class HTClassNamespace extends HTNamespace {
  HTClassNamespace(
      {String? id, String? classId, HTNamespace? closure, HTSource? source})
      : super(id: id, closure: closure, source: source);

  @override
  dynamic memberGet(String varName,
      {bool recursive = true, bool error = true}) {
    final getter = '${Semantic.getter}$varName';
    final externalStatic = '$id.$varName';

    if (declarations.containsKey(varName)) {
      final decl = declarations[varName]!;
      return decl.value;
    } else if (declarations.containsKey(getter)) {
      final decl = declarations[getter]!;
      return decl.value;
    } else if (declarations.containsKey(externalStatic)) {
      final decl = declarations[externalStatic]!;
      return decl.value;
    }

    if (recursive && (closure != null)) {
      return closure!.memberGet(varName);
    }

    if (error) {
      throw HTError.undefined(varName);
    }
  }

  @override
  void memberSet(String varName, dynamic varValue,
      {bool recursive = true, bool error = true}) {
    final setter = '${Semantic.setter}$varName';
    if (declarations.containsKey(varName)) {
      final decl = declarations[varName]!;
      decl.value = varValue;
      return;
    } else if (declarations.containsKey(setter)) {
      final setterFunc = declarations[setter] as HTFunction;
      setterFunc.call(positionalArgs: [varValue]);
      return;
    }

    if (recursive && closure != null) {
      closure!.memberSet(varName, varValue);
      return;
    }

    if (error) {
      throw HTError.undefined(varName);
    }
  }
}
