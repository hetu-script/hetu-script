import 'package:hetu_script/core/declaration.dart';

import '../../error/errors.dart';
import '../../grammar/lexicon.dart';
import '../abstract_interpreter.dart';
import '../declaration.dart';
import '../function/abstract_function.dart';
import 'namespace.dart';

/// A implementation of [HTNamespace] for [HTClass].
/// For interpreter searching for symbols within static methods.
class HTClassNamespace extends HTNamespace {
  HTClassNamespace(String id, String classId, HTInterpreter interpreter,
      {HTNamespace? closure})
      : super(interpreter, id: id, closure: closure);

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    final getter = '${HTLexicon.getter}$varName';
    final externalStatic = '$id.$varName';

    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[varName]!;
      return decl.value;
    } else if (declarations.containsKey(getter)) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[getter]!;
      return decl.value;
    } else if (declarations.containsKey(externalStatic)) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[externalStatic]!;
      return decl.value;
    }

    if (closure != null) {
      return closure!.fetch(varName, from: from);
    }

    throw HTError.undefined(varName);
  }

  @override
  void assign(String varName, dynamic varValue,
      {String from = HTLexicon.global}) {
    final setter = '${HTLexicon.setter}$varName';
    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[varName]!;
      if (decl is HTDeclaration) {
        decl.value = varValue;
        return;
      } else {
        throw HTError.immutable(varName);
      }
    } else if (declarations.containsKey(setter)) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final setterFunc = declarations[setter] as AbstractFunction;
      setterFunc.call(positionalArgs: [varValue]);
      return;
    }

    if (closure != null) {
      closure!.assign(varName, varValue, from: from);
      return;
    }

    throw HTError.undefined(varName);
  }
}
