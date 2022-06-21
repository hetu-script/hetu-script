import '../../error/error.dart';
import '../../grammar/constant.dart';
// import '../../source/source.dart';
import '../function/function.dart';
import '../namespace/namespace.dart';

/// A implementation of [HTNamespace] for [HTClass].
/// For interpreter searching for symbols within static methods.
class HTClassNamespace extends HTNamespace {
  HTClassNamespace({
    super.id,
    super.classId,
    super.closure,
    super.source,
  });

  @override
  dynamic memberGet(String varName,
      {bool isPrivate = false,
      String? from,
      bool isRecursive = true,
      bool throws = true}) {
    final getter = '${InternalIdentifier.getter}$varName';
    final externalStatic = '$id.$varName';

    if (symbols.containsKey(varName)) {
      final decl = symbols[varName]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      decl.resolve();
      return decl.value;
    } else if (symbols.containsKey(getter)) {
      final decl = symbols[getter]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      decl.resolve();
      return decl.value;
    } else if (symbols.containsKey(externalStatic)) {
      final decl = symbols[externalStatic]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      decl.resolve();
      return decl.value;
    }

    if (isRecursive && (closure != null)) {
      return closure!.memberGet(varName, from: from, isRecursive: isRecursive);
    }

    if (throws) {
      throw HTError.undefined(varName);
    }
  }

  @override
  bool memberSet(String varName, dynamic varValue,
      {String? from, bool isRecursive = true, bool throws = true}) {
    final setter = '${InternalIdentifier.setter}$varName';
    if (symbols.containsKey(varName)) {
      final decl = symbols[varName]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      decl.resolve();
      decl.value = varValue;
      return true;
    } else if (symbols.containsKey(setter)) {
      final decl = symbols[setter]!;
      if (decl.isPrivate && from != null && !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      decl.resolve();
      final setterFunc = decl as HTFunction;
      setterFunc.call(positionalArgs: [varValue]);
      return true;
    }

    if (isRecursive && closure != null) {
      return closure!.memberSet(varName, varValue, from: from);
    }

    if (throws) {
      throw HTError.undefined(varName);
    } else {
      return false;
    }
  }
}
