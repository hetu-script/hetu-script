import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/src/declaration.dart';

import 'lexicon.dart';
import 'namespace.dart';
import 'function.dart';
import 'errors.dart';
import 'type.dart';
import 'extern_function.dart';
import 'interpreter.dart';

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
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    if (fullName.startsWith(HTLexicon.underscore) && !fullName.startsWith(from)) {
      throw HTErrorPrivateDecl(fullName);
    } else if (varName.startsWith(HTLexicon.underscore) && !fullName.startsWith(from)) {
      throw HTErrorPrivateMember(varName);
    }
    final getter = '${HTLexicon.getter}$varName';
    final staticName = '$id.$varName';
    if (declarations.containsKey(varName)) {
      final decl = declarations[varName]!;
      if (!decl.isExtern) {
        if (!decl.isInitialized) {
          decl.initialize();
        }
        return decl.value;
      } else if (classType == ClassType.extern) {
        final externClass = interpreter.fetchExternalClass(id);
        return externClass.fetch(staticName);
      }
    } else if (declarations.containsKey(getter)) {
      final decl = declarations[getter]!;
      if (!decl.isExtern) {
        HTFunction func = declarations[getter]!.value;
        return func.call();
      } else if (classType == ClassType.extern) {
        final externClass = interpreter.fetchExternalClass(id);
        return externClass.fetch(staticName);
      } else {
        final externGetterFunc = interpreter.fetchExternalFunction('$id.${HTLexicon.getter}$varName');
        return externGetterFunc();
      }
    } else if (declarations.containsKey(staticName)) {
      final decl = declarations[staticName]!;
      if (!decl.isExtern) {
        return declarations[staticName]!.value;
      } else if (classType == ClassType.extern) {
        final externClass = interpreter.fetchExternalClass(id);
        return externClass.fetch(staticName);
      } else {
        return interpreter.fetchExternalFunction(staticName);
      }
    } else if (superClass != null && superClass!.contains(varName)) {
      return superClass!.fetch(varName, from: superClass!.fullName);
    }

    if (closure != null) {
      return closure!.fetch(varName, from: closure!.fullName);
    }

    throw HTErrorUndefined(varName);
  }

  /// Assign a value to a static member of this class.
  @override
  void assign(String varName, dynamic value, {String from = HTLexicon.global}) {
    if (fullName.startsWith(HTLexicon.underscore) && !fullName.startsWith(from)) {
      throw HTErrorPrivateDecl(fullName);
    } else if (varName.startsWith(HTLexicon.underscore) && !fullName.startsWith(from)) {
      throw HTErrorPrivateMember(varName);
    }

    final setter = '${HTLexicon.setter}$varName';
    final staticName = '$id.$varName';
    if (declarations.containsKey(varName)) {
      if (classType == ClassType.extern) {
        final externClass = interpreter.fetchExternalClass(id);
        externClass.assign(staticName, value);
      } else {
        final decl = declarations[varName]!;
        decl.assign(value);
      }
      return;
    } else if (declarations.containsKey(setter)) {
      HTFunction setterFunc = declarations[setter]!.value;
      if (!setterFunc.isExtern) {
        setterFunc.call(positionalArgs: [value]);
      } else if (classType == ClassType.extern) {
        final externClass = interpreter.fetchExternalClass(id);
        externClass.assign(staticName, value);
      } else {
        final externSetterFunc = interpreter.fetchExternalFunction('$id.${HTLexicon.setter}$varName');
        if (externSetterFunc is HTExternalFunction) {
          try {
            return externSetterFunc([value], const {});
          } on RangeError {
            throw HTErrorExternParams();
          }
        } else {
          return Function.apply(externSetterFunc, [value]);
          // throw HTErrorExternFunc(constructor.toString());
        }
      }
      return;
    }

    if (closure != null) {
      closure!.assign(varName, value, from: from);
      return;
    }

    throw HTErrorUndefined(varName);
  }

  /// Add a instance variable declaration to this class.
  void defineInstance(HTDeclaration decl, {bool skipOverride = false}) {
    if (!instanceDecls.containsKey(decl.id)) {
      instanceDecls[decl.id] = decl;
    } else {
      if (!skipOverride) throw HTErrorDefinedRuntime(decl.id);
    }
  }

  /// Create a instance from this class.
  /// TODO：对象初始化时从父类逐个调用构造函数
  HTInstance createInstance(
      {List<HTTypeId> typeArgs = const [],
      String? constructorName,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {}}) {
    var instance = HTInstance(this, interpreter, typeArgs: typeArgs.sublist(0, typeParams.length));

    var save = interpreter.curNamespace;
    interpreter.curNamespace = instance;
    for (final decl in instanceDecls.values) {
      instance.define(decl.clone());
    }
    interpreter.curNamespace = save;

    constructorName ??= id;
    if (declarations.containsKey(constructorName)) {
      HTFunction constructor = declarations[constructorName]!.value;
      constructor.context = instance;
      constructor.call(positionalArgs: positionalArgs, namedArgs: namedArgs);
    }

    return instance;
  }

  dynamic invoke(String funcName,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}}) {
    HTFunction? func = fetch(funcName, from: fullName);
    if ((func != null) && (!func.isStatic)) {
      return func.call(positionalArgs: positionalArgs, namedArgs: namedArgs);
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
      : super(interpreter, id: '${klass.id}.${HTLexicon.instance}${instanceIndex++}') {
    typeid = HTTypeId(klass.id, arguments: typeArgs = const []);
  }

  @override
  String toString() => '${HTLexicon.instanceOf}$typeid';

  @override
  bool contains(String varName) =>
      declarations.containsKey(varName) || declarations.containsKey('${HTLexicon.getter}$varName');

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    if (fullName.startsWith(HTLexicon.underscore) && !fullName.startsWith(from)) {
      throw HTErrorPrivateDecl(fullName);
    } else if (varName.startsWith(HTLexicon.underscore) && !fullName.startsWith(from)) {
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
        value.context = this;
      }
      return value;
    } else if (declarations.containsKey(getter)) {
      HTFunction method = declarations[getter]!.value;
      method.context = this;
      return method.call();
    }

    switch (varName) {
      case 'typeid':
        return typeid;
      case 'toString':
        return toString;
      default:
        throw HTErrorUndefinedMember(varName, typeid.toString());
    }
  }

  @override
  void assign(String varName, dynamic value, {String from = HTLexicon.global}) {
    if (fullName.startsWith(HTLexicon.underscore) && !fullName.startsWith(from)) {
      throw HTErrorPrivateDecl(fullName);
    } else if (varName.startsWith(HTLexicon.underscore) && !fullName.startsWith(from)) {
      throw HTErrorPrivateMember(varName);
    }

    final setter = '${HTLexicon.setter}$varName';
    if (declarations.containsKey(varName)) {
      if (isExtern) {
        final externClass = interpreter.fetchExternalClass(id);
        externClass.instanceAssign(this, varName, value);
      } else {
        final decl = declarations[varName]!;
        decl.assign(value);
      }
      return;
    } else if (declarations.containsKey(setter)) {
      HTFunction method = declarations[setter]!.value;
      method.context = this;
      method.call(positionalArgs: [value]);
      return;
    }

    throw HTErrorUndefined(varName);
  }

  dynamic invoke(String funcName,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}}) {
    HTFunction func = fetch(funcName, from: fullName);
    func.context = this;
    return func.call(positionalArgs: positionalArgs, namedArgs: namedArgs);
  }
}
