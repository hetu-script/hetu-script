import 'package:hetu_script/src/object.dart';

import 'errors.dart';
import 'lexicon.dart';
import 'type.dart';
import 'interpreter.dart';
import 'declaration.dart';
import 'function.dart';

class HTNamespace extends HTObject with InterpreterRef {
  static int spaceIndex = 0;

  static String getFullName(String id, HTNamespace? space) {
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
  final typeid = HTTypeId.namespace;

  late final String id;

  late final String fullName;

  // 变量表
  final Map<String, HTDeclaration> declarations = {};

  final HTNamespace? closure;

  HTNamespace(
    Interpreter interpreter, {
    String? id,
    this.closure,
  }) : super() {
    this.id = id ?? '${HTLexicon.anonymousNamespace}${spaceIndex++}';
    this.interpreter = interpreter;
    fullName = getFullName(this.id, closure);
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
      throw HTErrorDefinedRuntime(decl.id);
    }
  }

  /// 从当前命名空间，以及超空间，递归获取一个变量
  /// 注意和memberGet只是从对象本身取值不同
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    if (fullName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
      throw HTErrorPrivateDecl(fullName);
    } else if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
      throw HTErrorPrivateMember(varName);
    }

    if (declarations.containsKey(varName)) {
      final decl = declarations[varName]!;
      if (!decl.isInitialized) {
        decl.initialize();
      }
      final value = decl.value;
      if (value is HTFunction && value.externalTypedef != null) {
        final externalFunc = interpreter.unwrapExternalFunctionType(value.externalTypedef!, value);
        return externalFunc;
      }
      return value;
    }

    if (closure != null) {
      return closure!.fetch(varName, from: from);
    }

    throw HTErrorUndefined(varName);
  }

  dynamic fetchAt(String varName, int distance, {String from = HTLexicon.global}) {
    var space = closureAt(distance);
    return space.fetch(varName, from: from);
  }

  /// 从当前命名空间，以及超空间，递归获取一个变量并赋值
  /// 注意和memberSet只是对对象本身的成员赋值不同
  void assign(String varName, dynamic value, {String from = HTLexicon.global}) {
    if (fullName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
      throw HTErrorPrivateDecl(fullName);
    } else if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
      throw HTErrorPrivateMember(varName);
    }

    if (declarations.containsKey(varName)) {
      final decl = declarations[varName]!;
      decl.assign(value);
      return;
    }

    if (closure != null) {
      closure!.assign(varName, value, from: from);
      return;
    }

    throw HTErrorUndefined(varName);
  }

  void assignAt(String varName, dynamic value, int distance, {String from = HTLexicon.global}) {
    var space = closureAt(distance);
    space.assign(varName, value, from: from);
  }
}
