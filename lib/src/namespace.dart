import 'package:hetu_script/src/declaration.dart';
import 'package:hetu_script/src/object.dart';

import 'errors.dart';
import 'lexicon.dart';
import 'type.dart';
import 'interpreter.dart';
import 'variable.dart';
import 'function.dart';
import 'declaration.dart';

/// A implementation of [HTNamespace].
/// For interpreter searching for symbols from a certain block or module.
class HTNamespace with HTDeclaration, HTObject, InterpreterRef {
  static int _spaceIndex = 0;

  static String _getFullName(String id, HTNamespace? space) {
    var fullName = id;
    var curSpace = space;
    while (curSpace != null) {
      fullName = curSpace.id + HTLexicon.memberGet + fullName;
      curSpace = curSpace.closure;
    }
    return fullName;
  }

  @override
  String toString() => '${HTLexicon.NAMESPACE} $id';

  @override
  final typeid = HTTypeId.NAMESPACE;

  /// The full closure path of this namespace
  late final String fullName;

  /// [HTDeclaration]s in this [HTNamespace],
  /// could be [HTVariable], [HTFunction], [HTEnum] or [HTClass]
  final declarations = <String, HTDeclaration>{};

  /// [HTDeclaration]s in this [HTNamespace],
  /// could be [HTVariable], [HTFunction], [HTEnum] or [HTClass]
  final HTNamespace? closure;

  HTNamespace(
    Interpreter interpreter, {
    String? id,
    String? classId,
    this.closure,
  }) : super() {
    this.id = id ?? '${HTLexicon.anonymousNamespace}${_spaceIndex++}';
    this.classId = classId;
    this.interpreter = interpreter;
    fullName = _getFullName(this.id, closure);
  }

  HTNamespace closureAt(int distance) {
    var namespace = this;
    for (var i = 0; i < distance; ++i) {
      namespace = namespace.closure!;
    }

    return namespace;
  }

  /// 在当前命名空间定义一个变量的类型
  void define(HTDeclaration decl, {bool override = false}) {
    if (!declarations.containsKey(decl.id) || override) {
      declarations[decl.id] = decl;
    } else {
      throw HTError.definedRuntime(decl.id);
    }
  }

  /// 从当前命名空间，以及超空间，递归获取一个变量
  /// 注意和memberGet只是从对象本身取值不同
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[varName]!;
      if (decl is HTFunction) {
        if (decl.externalTypedef != null) {
          final externalFunc = interpreter.unwrapExternalFunctionType(
              decl.externalTypedef!, decl);
          return externalFunc;
        }
      } else if (decl is HTVariable) {
        if (!decl.isInitialized) {
          decl.initialize();
        }
        return decl.value;
      }
      return decl;
    }

    if (closure != null) {
      return closure!.fetch(varName, from: from);
    }

    throw HTError.undefined(varName);
  }

  dynamic fetchAt(String varName, int distance,
      {String from = HTLexicon.global}) {
    var space = closureAt(distance);
    return space.fetch(varName, from: from);
  }

  /// 从当前命名空间，以及超空间，递归获取一个变量并赋值
  /// 注意和memberSet只是对对象本身的成员赋值不同
  void assign(String varName, dynamic value, {String from = HTLexicon.global}) {
    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[varName]!;
      if (decl is HTVariable) {
        decl.assign(value);
        return;
      } else {
        throw HTError.immutable(varName);
      }
    }

    if (closure != null) {
      closure!.assign(varName, value, from: from);
      return;
    }

    throw HTError.undefined(varName);
  }

  void assignAt(String varName, dynamic value, int distance,
      {String from = HTLexicon.global}) {
    var space = closureAt(distance);
    space.assign(varName, value, from: from);
  }
}
