import '../common/errors.dart';
import 'lexicon.dart';
import 'type.dart';
import 'interpreter.dart';
import 'variable.dart';
import 'function.dart';
import 'declaration.dart';
import 'instance.dart';
import 'object.dart';

/// A implementation of [HTNamespace].
/// For interpreter searching for symbols from a certain block or module.
class HTNamespace extends HTDeclaration with HTObject, InterpreterRef {
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
  final objectType = HTType.NAMESPACE;

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
  }) : super(id ?? '${HTLexicon.anonymousNamespace}${_spaceIndex++}',
            classId: classId) {
    this.interpreter = interpreter;
    fullName = _getFullName(this.id, closure);
  }

  /// Search for a variable by the exact name and do not search recursively.
  @override
  bool contains(String varName) => declarations.containsKey(varName);

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
  void assign(String varName, dynamic varValue,
      {String from = HTLexicon.global}) {
    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[varName]!;
      if (decl is HTVariable) {
        decl.value = varValue;
        return;
      } else {
        throw HTError.immutable(varName);
      }
    }

    if (closure != null) {
      closure!.assign(varName, varValue, from: from);
      return;
    }

    throw HTError.undefined(varName);
  }

  void assignAt(String varName, dynamic varValue, int distance,
      {String from = HTLexicon.global}) {
    var space = closureAt(distance);
    space.assign(varName, varValue, from: from);
  }
}

/// A implementation of [HTNamespace] for [HTClass].
/// For interpreter searching for symbols within static methods.
class HTClassNamespace extends HTNamespace {
  HTClassNamespace(String id, String classId, Interpreter interpreter,
      {HTNamespace? closure})
      : super(interpreter, id: id, classId: classId, closure: closure);

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
    } else if (declarations.containsKey(getter)) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[getter] as HTFunction;
      return decl.call();
    } else if (declarations.containsKey(externalStatic)) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = declarations[externalStatic] as HTFunction;
      return decl;
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
      if (decl is HTVariable) {
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
      final setterFunc = declarations[setter] as HTFunction;
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

/// A implementation of [HTNamespace] for [HTInstance].
/// For interpreter searching for symbols within instance methods.
/// [HTInstanceNamespace] is a singly linked list node,
/// it holds its super classes' [HTInstanceNamespace]'s referrences.
class HTInstanceNamespace extends HTNamespace {
  final HTInstance instance;

  late final HTInstanceNamespace? next;

  HTInstanceNamespace(
      String id, String? classId, this.instance, Interpreter interpreter,
      {HTNamespace? closure})
      : super(interpreter, id: id, classId: classId, closure: closure);

  /// [HTInstanceNamespace] overrided [HTNamespace]'s [fetch],
  /// with a new named parameter [recursive].
  /// If [recursive] is false, then it won't continue to
  /// try fetching variable from enclosed namespace.
  @override
  dynamic fetch(String varName,
      {String from = HTLexicon.global, bool recursive = true}) {
    final getter = '${HTLexicon.getter}$varName';

    HTInstanceNamespace? curNamespace = this;
    while (curNamespace != null) {
      if (curNamespace.declarations.containsKey(varName) ||
          curNamespace.declarations.containsKey(getter)) {
        return instance.memberGet(varName,
            from: from, classId: curNamespace.classId);
      } else {
        curNamespace = curNamespace.next;
      }
    }

    if (recursive && closure != null) {
      return closure!.fetch(varName, from: from);
    }

    throw HTError.undefined(varName);
  }

  /// [HTInstanceNamespace] overrided [HTNamespace]'s [assign],
  /// with a new named parameter [recursive].
  /// If [recursive] is false, then it won't continue to
  /// try assigning variable from enclosed namespace.
  @override
  void assign(String varName, dynamic varValue,
      {String from = HTLexicon.global, bool recursive = true}) {
    final setter = '${HTLexicon.getter}$varName';

    HTInstanceNamespace? curNamespace = this;
    while (curNamespace != null) {
      if (curNamespace.declarations.containsKey(varName) ||
          curNamespace.declarations.containsKey(setter)) {
        instance.memberSet(varName, varValue,
            from: from, classId: curNamespace.classId);
        return;
      } else {
        curNamespace = curNamespace.next;
      }
    }

    if (recursive && closure != null) {
      closure!.assign(varName, varValue, from: from);
      return;
    }

    throw HTError.undefined(varName);
  }

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) =>
      fetch(varName, from: from, recursive: false);

  @override
  void memberSet(String varName, dynamic varValue,
          {String from = HTLexicon.global}) =>
      assign(varName, varValue, from: from, recursive: false);
}
