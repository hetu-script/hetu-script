import 'package:hetu_script/src/object.dart';

import 'lexicon.dart';
import 'namespace.dart';
import 'function.dart';
import 'errors.dart';
import 'type.dart';
import 'interpreter.dart';
import 'common.dart';
import 'variable.dart';
import 'declaration.dart';

abstract class HTClassType extends HTTypeId with HTDeclaration {
  @override
  String toString() => '${HTLexicon.CLASS} $id';

  @override
  bool contains(String varName);

  /// Fetch a instance member of the Dart class by the [varName], in the form of
  /// ```
  /// object.key
  /// ```
  dynamic instanceMemberGet(dynamic object, String varName) =>
      throw HTErrorUndefined(varName);

  /// Assign a value to a instance member of the Dart class by the [varName], in the form of
  /// ```
  /// object.key = value
  /// ```
  void instanceMemberSet(dynamic object, String varName, dynamic value) =>
      throw HTErrorUndefined(varName);

  /// Fetch a instance member of the Dart class by the [varName], in the form of
  /// ```
  /// object[key]
  /// ```
  dynamic instanceSubGet(dynamic object, dynamic key) =>
      throw HTErrorUndefined(key);

  /// Assign a value to a instance member of the Dart class by the [varName], in the form of
  /// ```
  /// object[key] = value
  /// ```
  void instanceSubSet(dynamic object, dynamic key, dynamic value) =>
      throw HTErrorUndefined(key);

  /// Create a default [HTClassType] instance.
  HTClassType(String id) : super(id, isNullable: false) {
    this.id = id;
  }
}

/// A implementation of [HTNamespace] for [HTClass].
/// For interpreter searching for symbols within class methods.
class HTClassNamespace extends HTNamespace {
  HTClassNamespace(String id, Interpreter interpreter, {HTNamespace? closure})
      : super(interpreter, id: id, closure: closure);

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    final getter = '${HTLexicon.getter}$varName';
    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final decl = declarations[varName]!;
      if (decl is HTFunction) {
        if (decl.externalTypedef != null) {
          final externalFunc = interpreter.unwrapExternalFunctionType(
              decl.externalTypedef!, decl);
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
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
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
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
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
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
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
/// [static] members in Hetu class are stored within a _namespace of [HTClassNamespace].
/// instance members of this class created by [createInstance] are stored in [_instanceMembers].
class HTClass extends HTClassType with InterpreterRef {
  var _instanceIndex = 0;

  @override
  final HTTypeId typeid = HTTypeId.CLASS;

  final HTClassNamespace namespace;

  late final ClassType _classType;
  ClassType get classType => _classType;

  /// The type parameters of the class.
  final List<String> typeParams;

  /// Super class of this class
  ///
  /// If a class is not extends from any super class, then it is the child of class `Object`
  HTClass? _superClass;

  /// The instance member variables defined in class definition.
  final _instanceMembers = <String, HTDeclaration>{};
  // final Map<String, HTClass> instanceNestedClasses = {};

  /// Create a default [HTClass] instance.
  HTClass(String id, this.namespace, Interpreter interpreter,
      {ClassType classType = ClassType.normal, this.typeParams = const []})
      : super(id) {
    this.interpreter = interpreter;
    _classType = classType;
  }

  /// This function is used after constructor,
  /// only the first non-null call will take effect.
  void inherit(HTClass? superClass) {
    if (_superClass != null) return;
    if (superClass == null) return;

    _superClass = superClass;

    // 继承所有父类的成员变量和方法，忽略掉已经被覆盖的那些
    HTClass? curSuper = superClass;
    while (curSuper != null) {
      for (final decl in curSuper._instanceMembers.values) {
        if (decl.id.startsWith(HTLexicon.underscore)) {
          continue;
        }
        defineInstanceMember(decl.clone(), error: false);
      }
      curSuper = curSuper._superClass;
    }
  }

  /// Wether there's a member in this [HTClass] by the [varName].
  @override
  bool contains(String varName) =>
      namespace.declarations.containsKey(varName) ||
      namespace.declarations.containsKey('${HTLexicon.getter}$varName') ||
      namespace.declarations.containsKey('$id.$varName');

  /// Get a value of a static member from this [HTClass].
  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    final getter = '${HTLexicon.getter}$varName';
    final constructor = '${HTLexicon.constructor}$varName';
    final externalName = '$id.$varName';

    if (namespace.declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(namespace.fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final decl = namespace.declarations[varName]!;
      if (decl is HTFunction) {
        if (decl.externalTypedef != null) {
          final externalFunc = interpreter.unwrapExternalFunctionType(
              decl.externalTypedef!, decl);
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
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(namespace.fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final func = namespace.declarations[getter] as HTFunction;
      return func.call();
    } else if (namespace.declarations.containsKey(constructor)) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(namespace.fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      return namespace.declarations[constructor] as HTFunction;
    } else if (namespace.declarations.containsKey(externalName) &&
        _classType == ClassType.extern) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(namespace.fullName)) {
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

  /// Assign a value to a static member of this [HTClass].
  @override
  void memberSet(String varName, dynamic value,
      {String from = HTLexicon.global}) {
    final setter = '${HTLexicon.setter}$varName';
    final externalName = '$id.$varName';

    if (namespace.declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(namespace.fullName)) {
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
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(namespace.fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final setterFunc = namespace.declarations[setter] as HTFunction;
      setterFunc.call(positionalArgs: [value]);
      return;
    } else if (namespace.declarations.containsKey(externalName) &&
        _classType == ClassType.extern) {
      final externClass = interpreter.fetchExternalClass(id);
      externClass.memberSet(externalName, value);
      return;
    }

    throw HTErrorUndefined(varName);
  }

  /// Call a static function of this [HTClass].
  dynamic invoke(String funcName,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const [],
      bool errorHandled = true}) {
    try {
      final func = memberGet(funcName, from: namespace.fullName);

      if (func is HTFunction) {
        return func.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        throw HTErrorCallable(funcName);
      }
    } catch (error, stack) {
      if (errorHandled) rethrow;

      interpreter.handleError(error, stack);
    }
  }

  /// Add a instance member declaration to this [HTClass].
  void defineInstanceMember(HTDeclaration decl,
      {bool override = false, bool error = true}) {
    if (decl is HTClass) {
      throw HTErrorClassOnInstance();
    }
    if ((!_instanceMembers.containsKey(decl.id)) || override) {
      _instanceMembers[decl.id] = decl;
    } else {
      if (error) throw HTErrorDefinedRuntime(decl.id);
    }
  }

  /// Create a [HTInstance] from this [HTClass].
  HTInstance createInstance(
      {String? constructorName,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []}) {
    var instance = HTInstance(this, interpreter, _instanceIndex++,
        typeArgs: typeArgs, closure: namespace);

    for (final decl in _instanceMembers.values) {
      if (decl is HTFunction) {
        instance.define(decl);
      } else if (decl is HTVariable) {
        instance.define(decl.clone());
      } else if (decl is HTClass) {}
    }

    final funcId = constructorName ?? HTLexicon.constructor;
    if (namespace.declarations.containsKey(funcId)) {
      /// TODO：对象初始化时从父类逐个调用构造函数
      final constructor = namespace.declarations[funcId] as HTFunction;
      constructor.context = instance;
      constructor.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);
    }

    return instance;
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) {
    if (_instanceMembers.containsKey(varName)) {
      final decl = _instanceMembers[varName];
      if (decl is HTFunction && decl.funcType != FunctionType.literal) {
        decl.context = object;
      }
      return decl;
    }
    throw HTErrorUndefined(varName);
  }
}

class HTCast with HTObject, InterpreterRef {
  @override
  late final HTTypeId typeid;

  final HTClass klass;

  late final HTObject object;

  HTCast(HTObject object, this.klass, Interpreter interpreter,
      {List<HTTypeId> typeArgs = const []}) {
    this.interpreter = interpreter;
    typeid = HTTypeId(klass.id, arguments: typeArgs);

    if (object is HTInstance) {
      final castee = interpreter.encapsulate(object);
      if (castee.isNotA(typeid)) {
        throw HTErrorTypeCast(object.toString(), typeid.toString());
      }
      this.object = object;
    } else if (object is HTCast) {
      final castee = interpreter.encapsulate(object.object);
      if (castee.isNotA(typeid)) {
        throw HTErrorTypeCast(object.object.toString(), typeid.toString());
      }
      this.object = object.object;
    } else {
      throw HTErrorCastee(interpreter.curSymbol!);
    }
  }

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) =>
      klass.instanceMemberGet(object, varName);

  @override
  void memberSet(String varName, dynamic value,
          {String from = HTLexicon.global}) =>
      klass.instanceMemberSet(object, varName, value);
}

/// The Dart implementation of the instance in Hetu.
/// [HTInstance] carries all decl from its super classes.
/// [HTInstance] inherits all its super classes' [HTTypeID]s.
class HTInstance extends HTNamespace {
  late final Set<HTTypeId> _typeids = <HTTypeId>{};

  @override
  HTTypeId get typeid => _typeids.first;

  /// Create a default [HTInstance] instance.
  HTInstance(HTClass klass, Interpreter interpreter, int index,
      {List<HTTypeId> typeArgs = const [], HTNamespace? closure})
      : super(interpreter,
            id: '${HTLexicon.instance}$index', closure: closure) {
    HTClass? curSuper = klass;
    while (curSuper != null) {
      // TODO: 父类没有type param怎么处理？
      final superTypeId = HTTypeId(curSuper.id, arguments: typeArgs);
      _typeids.add(superTypeId);
      curSuper = curSuper._superClass;
    }
  }

  /// Wether this object is of the type by [otherTypeId]
  @override
  bool isA(HTTypeId otherTypeId) {
    if (otherTypeId == HTTypeId.ANY) {
      return true;
    } else {
      for (final superTypeId in _typeids) {
        if (superTypeId == otherTypeId) {
          return true;
        }
      }
    }
    return false;
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
      declarations.containsKey(varName) ||
      declarations.containsKey('${HTLexicon.getter}$varName');

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
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final decl = declarations[varName]!;
      if (decl is HTFunction) {
        if (decl.externalTypedef != null) {
          final externalFunc = interpreter.unwrapExternalFunctionType(
              decl.externalTypedef!, decl);
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
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final method = declarations[getter] as HTFunction;
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
                List<HTTypeId> typeArgs = const []}) =>
            '${HTLexicon.instanceOf}$typeid';
      default:
        throw HTErrorUndefined(varName);
    }
  }

  @override
  void memberSet(String varName, dynamic value,
      {String from = HTLexicon.global}) {
    final setter = '${HTLexicon.setter}$varName';
    if (declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
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
      if (varName.startsWith(HTLexicon.underscore) &&
          !from.startsWith(fullName)) {
        throw HTErrorPrivateMember(varName);
      }
      final method = declarations[setter] as HTFunction;
      method.context = this;
      method.call(positionalArgs: [value]);
      return;
    }

    throw HTErrorUndefined(varName);
  }

  /// Call a member function of this [HTInstance].
  dynamic invoke(String funcName,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const [],
      bool errorHandled = true}) {
    try {
      HTFunction func = memberGet(funcName, from: fullName);
      return func.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);
    } catch (error, stack) {
      if (errorHandled) rethrow;

      interpreter.handleError(error, stack);
    }
  }
}
