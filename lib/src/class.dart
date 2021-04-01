import 'lexicon.dart';
import 'namespace.dart';
import 'function.dart';
import 'errors.dart';
import 'type.dart';
import 'interpreter.dart';
import 'common.dart';
import 'variable.dart';
import 'declaration.dart';

/// class 成员所在的命名空间，通常用于成员函数内部
/// 在没有 [this]，class id 的情况下检索变量
class HTClassNamespace extends HTNamespace {
  HTClassNamespace(String id, Interpreter interpreter, {HTNamespace? closure})
      : super(interpreter, id: id, closure: closure);

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    final getter = '${HTLexicon.getter}$varName';
    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final decl = declarations[varName]!;
      if (decl is HTFunction) {
        if (decl.externalTypedef != null) {
          final externalFunc = interpreter.unwrapExternalFunctionType(decl.externalTypedef!, decl);
          return externalFunc;
        }
        return decl;
      } else if (decl is HTVariable) {
        if (!decl.isInitialized) {
          decl.initialize();
        }
        return decl.value;
      } else if (decl is HTClass) {
        return null;
      }
    } else if (declarations.containsKey(getter)) {
      if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final decl = declarations[getter] as HTFunction;
      return decl.call();
    }

    if (closure != null) {
      return closure!.fetch(varName, from: from);
    }

    throw HTErrorUndefined(varName);
  }

  @override
  void assign(String varName, dynamic value, {String from = HTLexicon.global}) {
    final setter = '${HTLexicon.setter}$varName';
    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final decl = declarations[varName]!;
      if (decl is HTVariable) {
        decl.assign(value);
        return;
      } else {
        throw HTErrorImmutable(varName);
      }
    } else if (declarations.containsKey(setter)) {
      if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final setterFunc = declarations[setter] as HTFunction;
      setterFunc.call(positionalArgs: [value]);
      return;
    }

    if (closure != null) {
      closure!.assign(varName, value, from: from);
      return;
    }

    throw HTErrorUndefined(varName);
  }
}

/// [HTClass] is the Dart implementation of the class declaration in Hetu.
///
/// [HTClass] extends [HTNamespace].
///
/// The values defined in this namespace are methods and [static] members in Hetu class.
///
/// The [variables] are instance members.
///
/// Class can have type parameters.
///
/// Type parameters are optional and defined after class name. Example:
///
/// ```typescript
/// class Map<KeyType, ValueType> {
///   final keys: List<KeyType>
///   final values: List<ValueType>
///   ...
/// }
/// ```
class HTClass extends HTTypeId with HTDeclaration, InterpreterRef {
  var _instanceIndex = 0;

  @override
  String toString() => '${HTLexicon.CLASS} $id';

  @override
  final HTTypeId typeid = HTTypeId.CLASS;

  final HTClassNamespace namespace;

  final ClassType classType;

  /// The type parameters of the class.
  final List<String> typeParams;

  /// Super class of this class
  ///
  /// If a class is not extends from any super class, then it is the child of class `instance`
  final HTClass? superClass;

  /// The instance member variables defined in class definition.
  final instanceMembers = <String, HTDeclaration>{};
  // final Map<String, HTClass> instanceNestedClasses = {};

  /// Create a class instance.
  ///
  /// [id] : the class name
  ///
  /// [typeParams] : the type parameters defined after class name.
  ///
  /// [closure] : the outer namespace of the class declaration,
  /// normally the global namespace of the interpreter.
  HTClass(String id, this.namespace, this.superClass, Interpreter interpreter,
      {this.classType = ClassType.normal, this.typeParams = const []})
      : super(id, isNullable: false) {
    this.interpreter = interpreter;
    this.id = id;
  }

  @override
  bool contains(String varName) =>
      namespace.declarations.containsKey(varName) ||
      namespace.declarations.containsKey('${HTLexicon.getter}$varName') ||
      namespace.declarations.containsKey('$id.$varName');

  /// Get a value of a static member from this class.
  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    final getter = '${HTLexicon.getter}$varName';
    final externalName = '$id.$varName';
    if (namespace.declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(namespace.fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final decl = namespace.declarations[varName]!;
      if (decl is HTFunction) {
        if (decl.externalTypedef != null) {
          final externalFunc = interpreter.unwrapExternalFunctionType(decl.externalTypedef!, decl);
          return externalFunc;
        }
        return decl;
      } else if (decl is HTVariable) {
        if (!decl.isInitialized) {
          decl.initialize();
        }
        return decl.value;
      } else if (decl is HTClass) {
        return null;
      }
    } else if (namespace.declarations.containsKey(getter)) {
      if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(namespace.fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final func = namespace.declarations[getter]! as HTFunction;
      return func.call();
    } else if (namespace.declarations.containsKey(externalName) && classType == ClassType.extern) {
      if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(namespace.fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final decl = namespace.declarations[externalName]!;
      final externClass = interpreter.fetchExternalClass(id);
      if (decl is HTFunction) {
        return decl;
      } else if (decl is HTVariable) {
        return externClass.memberGet(externalName);
      } else if (decl is HTClass) {
        return null;
      }
    }

    throw HTErrorUndefined(varName);
  }

  /// Assign a value to a static member of this class.
  @override
  void memberSet(String varName, dynamic value, {String from = HTLexicon.global}) {
    final setter = '${HTLexicon.setter}$varName';
    final externalName = '$id.$varName';

    if (namespace.declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(namespace.fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final decl = namespace.declarations[varName]!;
      if (decl is HTVariable) {
        decl.assign(value);
        return;
      } else {
        throw HTErrorImmutable(varName);
      }
    } else if (namespace.declarations.containsKey(setter)) {
      if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(namespace.fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final setterFunc = namespace.declarations[setter]! as HTFunction;
      setterFunc.call(positionalArgs: [value]);
      return;
    } else if (namespace.declarations.containsKey(externalName) && classType == ClassType.extern) {
      final externClass = interpreter.fetchExternalClass(id);
      externClass.memberSet(externalName, value);
      return;
    }

    throw HTErrorUndefined(varName);
  }

  /// Add a instance member declaration to this class.
  void defineInstanceMember(HTDeclaration decl, {bool override = false, bool error = true}) {
    if (decl is HTClass) {
      throw HTErrorClassOnInstance();
    }
    if ((!instanceMembers.containsKey(decl.id)) || override) {
      instanceMembers[decl.id] = decl;
    } else {
      if (error) throw HTErrorDefinedRuntime(decl.id);
    }
  }

  /// Create a instance from this class.
  /// TODO：对象初始化时从父类逐个调用构造函数
  HTInstance createInstance(
      {String? constructorName = '',
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []}) {
    var instance = HTInstance(id, interpreter, _instanceIndex++, typeArgs: typeArgs, closure: namespace);

    for (final decl in instanceMembers.values) {
      if (decl is HTFunction) {
        instance.define(decl);
      } else if (decl is HTVariable) {
        instance.define(decl.clone());
      } else if (decl is HTClass) {}
    }

    final funcId = '${HTLexicon.constructor}$constructorName';
    if (namespace.declarations.containsKey(funcId)) {
      final constructor = namespace.declarations[funcId]! as HTFunction;
      constructor.context = instance;
      constructor.call(positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
    }

    return instance;
  }

  dynamic invoke(String funcName,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const [],
      bool errorHandled = false}) {
    try {
      final func = memberGet(funcName, from: namespace.fullName);

      if (func is HTFunction) {
        return func.call(positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
      } else {
        throw HTErrorCallable(funcName);
      }
    } catch (error, stack) {
      if (errorHandled) rethrow;

      interpreter.handleError(error, stack);
    }
  }
}

/// The Dart implementation of the instance instance in Hetu.
/// [HTInstance] has no closure, it carries all decl from its super class.
class HTInstance extends HTNamespace {
  @override
  late final HTTypeId typeid;

  HTInstance(String className, Interpreter interpreter, int index,
      {List<HTTypeId> typeArgs = const [], HTNamespace? closure})
      : super(interpreter, id: '${HTLexicon.instance}$index', closure: closure) {
    typeid = HTTypeId(className, arguments: typeArgs = const []);
  }

  @override
  String toString() {
    final func = memberGet('toString');
    if (func is HTFunction) {
      return func.call();
    } else if (func is Function) {
      return func();
    } else {
      return id;
    }
  }

  @override
  bool contains(String varName) =>
      declarations.containsKey(varName) || declarations.containsKey('${HTLexicon.getter}$varName');

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    if (contains(varName)) {
      return memberGet(varName, from: from);
    }

    if (closure != null) {
      return closure!.fetch(varName, from: from);
    }

    throw HTErrorUndefined(varName);
  }

  @override
  void assign(String varName, dynamic value, {String from = HTLexicon.global}) {
    if (contains(varName)) {
      memberSet(varName, value, from: from);
      return;
    }

    if (closure != null) {
      closure!.assign(varName, value, from: from);
      return;
    }

    throw HTErrorUndefined(varName);
  }

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    final getter = '${HTLexicon.getter}$varName';
    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final decl = declarations[varName]!;
      if (decl is HTFunction) {
        if (decl.externalTypedef != null) {
          final externalFunc = interpreter.unwrapExternalFunctionType(decl.externalTypedef!, decl);
          return externalFunc;
        }
        if (decl.funcType != FunctionType.literal) {
          decl.context = this;
        }
        return decl;
      } else if (decl is HTVariable) {
        if (!decl.isInitialized) {
          decl.initialize();
        }
        return decl.value;
      }
    } else if (declarations.containsKey(getter)) {
      if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final method = declarations[getter]! as HTFunction;
      method.context = this;
      return method.call();
    }

    // TODO: 这里应该改成写在脚本的Object上才对
    switch (varName) {
      case 'typeid':
        return typeid;
      case 'toString':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const <HTTypeId>[]}) =>
            '${HTLexicon.instanceOf}$typeid';
      default:
        throw HTErrorUndefined(varName);
    }
  }

  @override
  void memberSet(String varName, dynamic value, {String from = HTLexicon.global}) {
    final setter = '${HTLexicon.setter}$varName';
    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final decl = declarations[varName]!;
      if (decl is HTVariable) {
        decl.assign(value);
        return;
      } else {
        throw HTErrorImmutable(varName);
      }
    } else if (declarations.containsKey(setter)) {
      if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final method = declarations[setter]! as HTFunction;
      method.context = this;
      method.call(positionalArgs: [value]);
      return;
    }

    throw HTErrorUndefined(varName);
  }

  dynamic invoke(String funcName,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const [],
      bool errorHandled = false}) {
    try {
      HTFunction func = memberGet(funcName, from: fullName);
      return func.call(positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
    } catch (error, stack) {
      if (errorHandled) rethrow;

      interpreter.handleError(error, stack);
    }
  }
}
