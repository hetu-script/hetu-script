import '../../error/error.dart';
import '../../grammar/semantic.dart';
import '../../source/source.dart';
import '../function/function.dart';
import '../namespace.dart';

/// A implementation of [HTNamespace] for [HTClass].
/// For interpreter searching for symbols within static methods.
class HTClassNamespace extends HTNamespace {
  HTClassNamespace(
      {String? id, String? classId, HTNamespace? closure, HTSource? source})
      : super(id: id, closure: closure, source: source);

  @override
  dynamic memberGet(String field, {bool recursive = true, bool error = true}) {
    final getter = '${SemanticNames.getter}$field';
    final externalStatic = '$id.$field';

    if (declarations.containsKey(field)) {
      final decl = declarations[field]!;
      return decl.value;
    } else if (declarations.containsKey(getter)) {
      final decl = declarations[getter]!;
      return decl.value;
    } else if (declarations.containsKey(externalStatic)) {
      final decl = declarations[externalStatic]!;
      return decl.value;
    }

    if (recursive && (closure != null)) {
      return closure!.memberGet(field);
    }

    if (error) {
      throw HTError.undefined(field);
    }
  }

  @override
  void memberSet(String field, dynamic varValue,
      {bool recursive = true, bool error = true}) {
    final setter = '${SemanticNames.setter}$field';
    if (declarations.containsKey(field)) {
      final decl = declarations[field]!;
      decl.value = varValue;
      return;
    } else if (declarations.containsKey(setter)) {
      final setterFunc = declarations[setter] as HTFunction;
      setterFunc.call(positionalArgs: [varValue]);
      return;
    }

    if (recursive && closure != null) {
      closure!.memberSet(field, varValue);
      return;
    }

    if (error) {
      throw HTError.undefined(field);
    }
  }
}
