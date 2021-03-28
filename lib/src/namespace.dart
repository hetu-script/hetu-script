import 'errors.dart';
import 'lexicon.dart';
import 'type.dart';
import 'interpreter.dart';
import 'declaration.dart';
import 'object.dart';
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

  @override
  late final String fullName;

  // 变量表
  final Map<String, HTDeclaration> declarations = {};

  HTNamespace? closure;

  HTNamespace(
    Interpreter interpreter, {
    String? id,
    HTNamespace? closure,
  }) : super() {
    this.id = id ?? '${HTLexicon.anonymousNamespace}${spaceIndex++}';
    this.interpreter = interpreter;
    fullName = getFullName(this.id, closure);
    if (this.id != HTLexicon.global) {
      this.closure = closure ?? interpreter.curNamespace;
    } else {
      this.closure = closure;
    }
  }

  HTNamespace closureAt(int distance) {
    var namespace = this;
    for (var i = 0; i < distance; ++i) {
      namespace = namespace.closure!;
    }

    return namespace;
  }

  @override
  bool contains(String varName) {
    if (declarations.containsKey(varName)) {
      return true;
    }
    if (closure != null) {
      return closure!.contains(varName);
    }
    return false;
  }

  /// 在当前命名空间定义一个变量的类型
  @override
  void define(HTDeclaration decl, {bool override = false}) {
    if (!declarations.containsKey(decl.id) || override) {
      declarations[decl.id] = decl;
    } else {
      throw HTErrorDefinedRuntime(decl.id);
    }
  }

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
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
      } else {
        return value;
      }
    }

    if (closure != null) {
      return closure!.memberGet(varName, from: from);
    }

    throw HTErrorUndefined(varName);
  }

  dynamic fetchAt(String varName, int distance, {String from = HTLexicon.global}) {
    var space = closureAt(distance);
    return space.memberGet(varName, from: from);
  }

  /// 向一个已经定义的变量赋值
  @override
  void memberSet(String varName, dynamic value, {String from = HTLexicon.global}) {
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
      closure!.memberSet(varName, value, from: from);
      return;
    }

    throw HTErrorUndefined(varName);
  }

  void assignAt(String varName, dynamic value, int distance, {String from = HTLexicon.global}) {
    var space = closureAt(distance);
    space.memberSet(
      varName,
      value,
      from: space.fullName,
    );
  }
}
