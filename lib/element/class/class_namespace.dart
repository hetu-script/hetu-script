import '../../error/error.dart';
import '../../grammar/lexicon.dart';
import '../../grammar/semantic.dart';
import '../../interpreter/abstract_interpreter.dart';
import '../../element/typed_variable_declaration.dart';
import '../function/function.dart';
import '../namespace.dart';

/// A implementation of [HTNamespace] for [HTClass].
/// For interpreter searching for symbols within static methods.
class HTClassNamespace extends HTNamespace {
  HTClassNamespace(String id, String classId, AbstractInterpreter interpreter,
      {HTNamespace? closure})
      : super(interpreter, id: id, closure: closure);

  @override
  dynamic memberGet(String varName,
      {String from = SemanticNames.global,
      bool recursive = true,
      bool error = true}) {
    final getter = '${SemanticNames.getter}$varName';
    final externalStatic = '$id.$varName';

    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[varName]!;
      return decl.value;
    } else if (declarations.containsKey(getter)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[getter]!;
      return decl.value;
    } else if (declarations.containsKey(externalStatic)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[externalStatic]!;
      return decl.value;
    }

    if (recursive && (closure != null)) {
      return closure!.memberGet(varName, from: from);
    }

    if (error) {
      throw HTError.undefined(varName);
    }
  }

  @override
  void memberSet(String varName, dynamic varValue,
      {String from = SemanticNames.global, bool error = true}) {
    final setter = '${SemanticNames.setter}$varName';
    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[varName]!;
      if (decl is TypedVariableDeclaration) {
        decl.value = varValue;
        return;
      } else {
        throw HTError.immutable(varName);
      }
    } else if (declarations.containsKey(setter)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final setterFunc = declarations[setter] as HTFunction;
      setterFunc.call(positionalArgs: [varValue]);
      return;
    }

    if (closure != null) {
      closure!.memberSet(varName, varValue, from: from);
      return;
    }

    if (error) {
      throw HTError.undefined(varName);
    }
  }
}
