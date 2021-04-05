import 'lexicon.dart';
import 'namespace.dart';
import 'function.dart';
import 'errors.dart';
import 'type.dart';
import 'interpreter.dart';
import 'common.dart';
import 'variable.dart';
import 'declaration.dart';
import 'instance.dart';
import 'enum.dart';

/// A implementation of [HTNamespace] for [HTClass].
/// For interpreter searching for symbols within static methods.
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
/// instance members of this class created by [createInstance] are stored in [instanceMembers].
class HTClass extends HTTypeId with HTDeclaration, InterpreterRef {
  @override
  String toString() => '${HTLexicon.CLASS} $id';

  var _instanceIndex = 0;

  @override
  final HTTypeId typeid = HTTypeId.CLASS;

  late final HTClassNamespace namespace;

  late final ClassType _classType;
  ClassType get classType => _classType;

  /// The type parameters of the class.
  final List<String> typeParams;

  /// Super class of this class
  ///
  /// If a class is not extends from any super class, then it is the child of class `Object`
  final HTClass? superClass;

  /// The instance member variables defined in class definition.
  final instanceMembers = <String, HTDeclaration>{};
  // final Map<String, HTClass> instanceNestedClasses = {};

  /// Create a default [HTClass] instance.
  HTClass(
      String id, this.superClass, Interpreter interpreter, HTNamespace closure,
      {ClassType classType = ClassType.normal, this.typeParams = const []})
      : super(id, isNullable: false) {
    this.id = id;
    this.interpreter = interpreter;

    namespace = HTClassNamespace(id, interpreter, closure: closure);

    _classType = classType;
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
    if (decl is HTClass || decl is HTEnum) {
      throw HTErrorClassOnInstance();
    }
    if ((!instanceMembers.containsKey(decl.id)) || override) {
      instanceMembers[decl.id] = decl;
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
    var instance =
        HTInstance(this, interpreter, _instanceIndex++, typeArgs: typeArgs);

    final funcId = constructorName ?? HTLexicon.constructor;
    if (namespace.declarations.containsKey(funcId)) {
      /// TODO：对象初始化时从父类逐个调用构造函数
      final constructor = namespace.declarations[funcId] as HTFunction;
      constructor.context = instance.namespace;
      constructor.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);
    }

    return instance;
  }
}
