import 'lexicon.dart';
import 'namespace.dart';
import 'function.dart';
import 'errors.dart';
import 'type.dart';
import 'interpreter.dart';
import 'common.dart';
import 'declaration.dart';

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
///   List<KeyType> keys
///   List<ValueType> values
///   ...
/// }
/// ```
class HTClass extends HTNamespace {
  @override
  String toString() => '${HTLexicon.CLASS} $id';

  @override
  final HTTypeId typeid = HTTypeId.CLASS;

  final ClassType classType;

  /// The type parameters of the class.
  final List<String> typeParams;

  /// Super class of this class
  ///
  /// If a class is not extends from any super class, then it is the child of class `instance`
  final HTClass? superClass;

  /// The instance members defined in class definition.
  final Map<String, HTDeclaration> instanceDecls = {};

  /// Create a class instance.
  ///
  /// [id] : the class name
  ///
  /// [typeParams] : the type parameters defined after class name.
  ///
  /// [closure] : the outer namespace of the class declaration,
  /// normally the global namespace of the interpreter.
  ///
  /// [superClass] : super class of this class.
  HTClass(String id, this.superClass, Interpreter interpreter,
      {this.classType = ClassType.normal, this.typeParams = const [], HTNamespace? closure})
      : super(interpreter, id: id, closure: closure);

  /// Wether the class contains a static member, will also check super class.
  @override
  bool contains(String varName) =>
      declarations.containsKey(varName) ||
      declarations.containsKey('${HTLexicon.getter}$varName') ||
      ((superClass?.contains(varName)) ?? false) ||
      ((superClass?.contains('${HTLexicon.getter}$varName')) ?? false);

  /// Fetch the value of a static member from this class.
  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    if (fullName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
      throw HTErrorPrivateDecl(fullName);
    } else if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
      throw HTErrorPrivateMember(varName);
    }

    final staticName = '$id.$varName';
    if (classType == ClassType.extern) {
      final externClass = interpreter.fetchExternalClass(id);
      return externClass.memberGet(staticName);
    }

    final getter = '${HTLexicon.getter}$varName';
    if (declarations.containsKey(varName)) {
      final decl = declarations[varName]!;
      if (!decl.isInitialized) {
        decl.initialize();
      }
      final value = decl.value;
      if (value is HTFunction) {
        if (value.externalTypedef != null) {
          final externalFunc = interpreter.unwrapExternalFunctionType(value.externalTypedef!, value);
          return externalFunc;
        } else {
          return value;
        }
      }
      return value;
    } else if (declarations.containsKey(getter)) {
      final decl = declarations[getter]!;
      HTFunction func = decl.value;
      return func.call();
    } else if (superClass != null && superClass!.contains(varName)) {
      return superClass!.memberGet(varName, from: from);
    }

    if (closure != null) {
      return closure!.memberGet(varName, from: from);
    }

    throw HTErrorUndefined(varName);
  }

  /// Assign a value to a static member of this class.
  @override
  void memberSet(String varName, dynamic value, {String from = HTLexicon.global}) {
    if (fullName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
      throw HTErrorPrivateDecl(fullName);
    } else if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
      throw HTErrorPrivateMember(varName);
    }

    final staticName = '$id.$varName';
    if (classType == ClassType.extern) {
      final externClass = interpreter.fetchExternalClass(id);
      externClass.memberSet(staticName, value);
      return;
    }

    final setter = '${HTLexicon.setter}$varName';
    if (declarations.containsKey(varName)) {
      final decl = declarations[varName]!;
      decl.assign(value);
      return;
    } else if (declarations.containsKey(setter)) {
      HTFunction setterFunc = declarations[setter]!.value;
      setterFunc.call(positionalArgs: [value]);
      return;
    }

    if (closure != null) {
      closure!.memberSet(varName, value, from: from);
      return;
    }

    throw HTErrorUndefined(varName);
  }

  /// Add a instance variable declaration to this class.
  void defineInstance(HTDeclaration decl, {bool override = false, bool error = true}) {
    if (!instanceDecls.containsKey(decl.id) || override) {
      instanceDecls[decl.id] = decl;
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
    var instance = HTInstance(this, interpreter, typeArgs: typeArgs.sublist(0, typeParams.length));

    for (final decl in instanceDecls.values) {
      instance.define(decl.clone());
    }

    final funcId = '${HTLexicon.constructor}$constructorName';
    if (declarations.containsKey(funcId)) {
      HTFunction constructor = declarations[funcId]!.value;
      constructor.context = instance;
      constructor.call(positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
    }

    return instance;
  }

  dynamic invoke(String funcName,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []}) {
    HTFunction? func = memberGet(funcName, from: fullName);
    if ((func != null) && (!func.isStatic)) {
      return func.call(positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
    }

    throw HTErrorUndefined(funcName);
  }
}

/// [HTInstance] is the Dart implementation of the instance instance in Hetu.
class HTInstance extends HTNamespace {
  static var instanceIndex = 0;

  final bool isExtern;

  final HTClass klass;

  @override
  late final HTTypeId typeid;

  HTInstance(this.klass, Interpreter interpreter, {List<HTTypeId> typeArgs = const [], this.isExtern = false})
      : super(interpreter, id: '${HTLexicon.instance}${instanceIndex++}', closure: klass) {
    typeid = HTTypeId(klass.id, arguments: typeArgs = const []);
  }

  @override
  String toString() {
    dynamic func = memberGet('toString');
    return interpreter.call(func);
  }

  @override
  bool contains(String varName) =>
      declarations.containsKey(varName) || declarations.containsKey('${HTLexicon.getter}$varName');

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    if (fullName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
      throw HTErrorPrivateDecl(fullName);
    } else if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
      throw HTErrorPrivateMember(varName);
    }

    final getter = '${HTLexicon.getter}$varName';
    if (declarations.containsKey(varName)) {
      final decl = declarations[varName]!;
      if (!decl.isInitialized) {
        decl.initialize();
      }
      final value = decl.value;
      if (value is HTFunction) {
        if (value.externalTypedef != null) {
          final externalFunc = interpreter.unwrapExternalFunctionType(value.externalTypedef!, value);
          return externalFunc;
        }
        if (value.context == null) {
          value.context = this;
          return value;
        }
        return value;
      } else {
        return value;
      }
    } else if (declarations.containsKey(getter)) {
      HTFunction method = declarations[getter]!.value;
      method.context = this;
      return method.call();
    }

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
        if (closure != null) {
          return closure!.memberGet(varName, from: from);
        }
        throw HTErrorUndefined(varName);
    }
  }

  @override
  void memberSet(String varName, dynamic value, {String from = HTLexicon.global}) {
    if (fullName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
      throw HTErrorPrivateDecl(fullName);
    } else if (varName.startsWith(HTLexicon.underscore) && !from.startsWith(fullName)) {
      throw HTErrorPrivateMember(varName);
    }

    final setter = '${HTLexicon.setter}$varName';
    if (declarations.containsKey(varName)) {
      final decl = declarations[varName]!;
      decl.assign(value);
      return;
    } else if (declarations.containsKey(setter)) {
      HTFunction method = declarations[setter]!.value;
      method.context = this;
      method.call(positionalArgs: [value]);
      return;
    }

    if (closure != null) {
      return closure!.memberSet(varName, value, from: from);
    }

    throw HTErrorUndefined(varName);
  }

  dynamic invoke(String funcName,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []}) {
    HTFunction func = memberGet(funcName, from: fullName);
    func.context = this;
    return func.call(positionalArgs: positionalArgs, namedArgs: namedArgs, typeArgs: typeArgs);
  }
}
