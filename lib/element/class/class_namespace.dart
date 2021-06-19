import '../../error/error.dart';
import '../../grammar/lexicon.dart';
import '../../grammar/semantic.dart';
import '../../interpreter/abstract_interpreter.dart';
import '../variable/typed_variable_declaration.dart';
import '../function/function.dart';
import '../namespace.dart';

/// A implementation of [HTNamespace] for [HTClass].
/// For interpreter searching for symbols within static methods.
class HTClassNamespace extends HTNamespace {
  HTClassNamespace(String id, String classId, String moduleFullName,
      String libraryName, AbstractInterpreter interpreter,
      {HTNamespace? closure})
      : super(moduleFullName, libraryName, id: id, closure: closure);

  @override
  dynamic memberGet(String field,
      {String from = SemanticNames.global,
      bool recursive = true,
      bool error = true}) {
    final getter = '${SemanticNames.getter}$field';
    final externalStatic = '$id.$field';

    if (declarations.containsKey(field)) {
      if (field.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(field);
      }
      final decl = declarations[field]!;
      return decl.value;
    } else if (declarations.containsKey(getter)) {
      if (field.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(field);
      }
      final decl = declarations[getter]!;
      return decl.value;
    } else if (declarations.containsKey(externalStatic)) {
      if (field.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(field);
      }
      final decl = declarations[externalStatic]!;
      return decl.value;
    }

    if (recursive && (closure != null)) {
      return closure!.memberGet(field, from: from);
    }

    if (error) {
      throw HTError.undefined(field);
    }
  }

  @override
  void memberSet(String field, dynamic varValue,
      {String from = SemanticNames.global, bool error = true}) {
    final setter = '${SemanticNames.setter}$field';
    if (declarations.containsKey(field)) {
      if (field.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(field);
      }
      final decl = declarations[field]!;
      if (decl is HTTypedVariableDeclaration) {
        decl.value = varValue;
        return;
      } else {
        throw HTError.immutable(field);
      }
    } else if (declarations.containsKey(setter)) {
      if (field.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(field);
      }
      final setterFunc = declarations[setter] as HTFunction;
      setterFunc.call(positionalArgs: [varValue]);
      return;
    }

    if (closure != null) {
      closure!.memberSet(field, varValue, from: from);
      return;
    }

    if (error) {
      throw HTError.undefined(field);
    }
  }
}
