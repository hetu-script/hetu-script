import 'lexicon.dart';
import 'ast_interpreter.dart';
import 'namespace.dart';
import 'function.dart';
import 'errors.dart';
import 'expression.dart';
import 'type.dart';

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
  final HTTypeId typeid = HTTypeId.CLASS;

  /// The type parameters of the class.
  final List<String> typeParams;

  @override
  String toString() => '${HTLexicon.CLASS} $id';

  final bool isExtern;

  /// Super class of this class
  ///
  /// If a class is not extends from any super class, then it is the child of class `instance`
  final HTClass? superClass;

  /// The instance members defined in class definition.
  Map<String, VarDeclStmt> variables = {};

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
  HTClass(String id, this.superClass, HTInterpreter interpreter,
      {this.isExtern = false, this.typeParams = const [], HTNamespace? closure})
      : super(interpreter, id: id, closure: closure);

  /// Wether the class contains a static member, will also check super class.
  @override
  bool contains(String varName) =>
      defs.containsKey(varName) ||
      defs.containsKey('${HTLexicon.getter}$varName') ||
      ((superClass?.contains(varName)) ?? false) ||
      ((superClass?.contains('${HTLexicon.getter}$varName')) ?? false);

  /// Add a instance variable declaration to this class.
  void declareVar(VarDeclStmt stmt) {
    if (!variables.containsKey(stmt.id.lexeme)) {
      variables[stmt.id.lexeme] = stmt;
    } else {
      throw HTErrorDefined_Runtime(stmt.id.lexeme);
    }
  }

  /// Fetch the value of a static member from this class.
  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    if (fullName.startsWith(HTLexicon.underscore) && !fullName.startsWith(from)) {
      throw HTErrorPrivateDecl(fullName);
    } else if (varName.startsWith(HTLexicon.underscore) && !fullName.startsWith(from)) {
      throw HTErrorPrivateMember(varName);
    }
    var getter = '${HTLexicon.getter}$varName';
    var constructor = '$id.$varName';
    if (defs.containsKey(varName)) {
      var decl = defs[varName]!;
      if (!decl.isExtern) {
        return decl.value;
      } else {
        if (isExtern) {
          final externClass = interpreter.fetchExternalClass(id);
          return externClass.fetch(varName);
        } else {
          return interpreter.getExternalVariable('$id.$varName');
        }
      }
    } else if (defs.containsKey(getter)) {
      var decl = defs[getter]!;
      if (!decl.isExtern) {
        HTFunction func = defs[getter]!.value;
        return func.call();
      } else {
        final externClass = interpreter.fetchExternalClass(id);
        final Function getterFunc = externClass.fetch(varName);
        return getterFunc();
      }
    } else if (defs.containsKey(constructor)) {
      var decl = defs[constructor]!;
      if (!decl.isExtern) {
        return defs[constructor]!.value;
      } else {
        final externClass = interpreter.fetchExternalClass(id);
        return externClass.fetch(constructor);
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

    var setter = '${HTLexicon.setter}$varName';
    if (defs.containsKey(varName)) {
      var decl_type = defs[varName]!.declType;
      var var_type = interpreter.typeof(value);
      if (var_type.isA(decl_type)) {
        var decl = defs[varName]!;
        if (!decl.isImmutable) {
          if (!decl.isExtern) {
            decl.value = value;
            return;
          } else {
            if (isExtern) {
              final externClass = interpreter.fetchExternalClass(id);
              externClass.assign(varName, value);
              return;
            } else {
              interpreter.setExternalVariable('$id.$varName', value);
              return;
            }
          }
        }
        throw HTErrorImmutable(varName);
      }
      throw HTErrorTypeCheck(varName, var_type.toString(), decl_type.toString());
    } else if (defs.containsKey(setter)) {
      HTFunction setterFunc = defs[setter]!.value;
      if (!setterFunc.isExtern) {
        setterFunc.call(positionalArgs: [value]);
        return;
      } else {
        if (isExtern) {
          final externClass = interpreter.fetchExternalClass(id);
          externClass.assign(varName, value);
          return;
        } else {
          final externSetterFunc = interpreter.fetchExternalFunction('$id.$setter');
          externSetterFunc([value], const {});
          return;
        }
      }
    }

    if (closure != null) {
      closure!.assign(varName, value, from: from);
      return;
    }

    throw HTErrorUndefined(varName);
  }

  /// Create a instance from this class.
  /// TODO：对象初始化时从父类逐个调用构造函数
  HTInstance createInstance(HTInterpreter interpreter, int? line, int? column,
      {List<HTTypeId> typeArgs = const [],
      String? constructorName,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {}}) {
    var instance = HTInstance(this, interpreter, typeArgs: typeArgs.sublist(0, typeParams.length));

    var save = interpreter.curNamespace;
    interpreter.curNamespace = instance;
    for (final decl in variables.values) {
      dynamic value;
      if (decl.initializer != null) {
        value = interpreter.visitASTNode(decl.initializer!);
      }
      instance.define(decl.id.lexeme, declType: decl.declType, value: value);
    }
    interpreter.curNamespace = save;

    constructorName ??= id;
    var constructor = fetch(constructorName, from: fullName);

    if (constructor is HTFunction) {
      constructor.call(positionalArgs: positionalArgs, namedArgs: namedArgs, instance: instance);
    }

    return instance;
  }
}

/// [HTInstance] is the Dart implementation of the instance instance in Hetu.
class HTInstance extends HTNamespace {
  static var instanceIndex = 0;

  final bool isExtern;

  final HTClass klass;

  @override
  late final HTTypeId typeid;

  HTInstance(this.klass, HTInterpreter interpreter, {List<HTTypeId> typeArgs = const [], this.isExtern = false})
      : super(interpreter, id: '${HTLexicon.instance}${instanceIndex++}', closure: klass) {
    typeid = HTTypeId(klass.id, arguments: typeArgs = const []);
    define(HTLexicon.THIS, declType: typeid, value: this);
  }

  @override
  String toString() => '${HTLexicon.instanceOf}$typeid';

  @override
  bool contains(String varName) => defs.containsKey(varName) || defs.containsKey('${HTLexicon.getter}$varName');

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    if (fullName.startsWith(HTLexicon.underscore) && !fullName.startsWith(from)) {
      throw HTErrorPrivateDecl(fullName);
    } else if (varName.startsWith(HTLexicon.underscore) && !fullName.startsWith(from)) {
      throw HTErrorPrivateMember(varName);
    }

    var getter = '${HTLexicon.getter}$varName';
    if (defs.containsKey(varName)) {
      return defs[varName]!.value;
    } else if (klass.contains(getter)) {
      HTFunction method = klass.fetch(getter, from: klass.fullName);
      if (!method.funcStmt.isStatic) {
        return method.call(instance: this);
      }
    } else if (klass.contains(varName)) {
      final method = klass.fetch(varName, from: klass.fullName);
      if (method is HTFunction && !method.funcStmt.isStatic) {
        method.declContext = this;
        return method;
      }
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

    if (defs.containsKey(varName)) {
      var decl_type = defs[varName]!.declType;
      var var_type = interpreter.typeof(value);
      if (var_type.isA(decl_type)) {
        if (!defs[varName]!.isImmutable) {
          defs[varName]!.value = value;
          return;
        }
        throw HTErrorImmutable(varName);
      }
      throw HTErrorTypeCheck(varName, var_type.toString(), decl_type.toString());
    } else {
      var setter = '${HTLexicon.setter}$varName';
      if (klass.contains(setter)) {
        HTFunction? method = klass.fetch(setter, from: klass.fullName);
        if ((method != null) && (!method.funcStmt.isStatic)) {
          method.call(positionalArgs: [value], instance: this);
          return;
        }
      }
    }

    throw HTErrorUndefined(varName);
  }

  dynamic invoke(String methodName,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}}) {
    HTFunction? method = klass.fetch(methodName, from: klass.fullName);
    if ((method != null) && (!method.funcStmt.isStatic)) {
      return method.call(positionalArgs: positionalArgs, namedArgs: namedArgs, instance: this);
    }

    throw HTErrorUndefined(methodName);
  }
}
