import '../../error/error.dart';
import '../../grammar/constant.dart';
import '../../source/source.dart';
import '../function/function.dart';
import '../namespace/namespace.dart';

/// A implementation of [HTNamespace] for [HTClass].
/// For interpreter searching for symbols within static methods.
class HTClassNamespace extends HTNamespace {
  HTClassNamespace(
      {String? id, String? classId, HTNamespace? closure, HTSource? source})
      : super(id: id, closure: closure, source: source);

  @override
  dynamic memberGet(String varName,
      {String? from, bool recursive = true, bool error = true}) {
    final getter = '${InternalIdentifier.getter}$varName';
    final externalStatic = '$id.$varName';

    if (declarations.containsKey(varName)) {
      final decl = declarations[varName]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      return decl.value;
    } else if (declarations.containsKey(getter)) {
      final decl = declarations[getter]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      return decl.value;
    } else if (declarations.containsKey(externalStatic)) {
      final decl = declarations[externalStatic]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      return decl.value;
    }

    if (recursive && (closure != null)) {
      return closure!.memberGet(varName, from: from, recursive: recursive);
    }

    if (error) {
      throw HTError.undefined(varName);
    }
  }

  @override
  bool memberSet(String varName, dynamic varValue,
      {String? from, bool recursive = true, bool error = true}) {
    final setter = '${InternalIdentifier.setter}$varName';
    if (declarations.containsKey(varName)) {
      final decl = declarations[varName]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      decl.value = varValue;
      return true;
    } else if (declarations.containsKey(setter)) {
      final decl = declarations[setter]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final setterFunc = decl as HTFunction;
      setterFunc.call(positionalArgs: [varValue]);
      return true;
    }

    if (recursive && closure != null) {
      return closure!.memberSet(varName, varValue, from: from);
    }

    if (error) {
      throw HTError.undefined(varName);
    } else {
      return false;
    }
  }
}
