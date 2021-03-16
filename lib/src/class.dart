import 'lexicon.dart';
import 'ast_interpreter.dart';
import 'namespace.dart';
import 'function.dart';
import 'errors.dart';
import 'expression.dart';
import 'type.dart';

/// [HT_Class] is the Dart implementation of the class declaration in Hetu.
///
/// [HT_Class] extends [HT_Namespace].
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
class HT_Class extends HT_Namespace {
  @override
  final HT_TypeId typeid = HT_TypeId.CLASS;

  /// The type parameters of the class.
  final List<String> typeParams;

  @override
  String toString() => '${HT_Lexicon.CLASS} $id';

  final bool isExtern;

  /// Super class of this class
  ///
  /// If a class is not extends from any super class, then it is the child of class `instance`
  final HT_Class? superClass;

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
  HT_Class(String id, this.superClass, HT_ASTInterpreter interpreter,
      {this.isExtern = false, this.typeParams = const [], HT_Namespace? closure})
      : super(interpreter, id: id, closure: closure);

  /// Wether the class contains a static member, will also check super class.
  @override
  bool contains(String varName) =>
      defs.containsKey(varName) ||
      defs.containsKey('${HT_Lexicon.getter}$varName') ||
      ((superClass?.contains(varName)) ?? false) ||
      ((superClass?.contains('${HT_Lexicon.getter}$varName')) ?? false);

  /// Add a instance variable declaration to this class.
  void declareVar(VarDeclStmt stmt) {
    if (!variables.containsKey(stmt.id.lexeme)) {
      variables[stmt.id.lexeme] = stmt;
    } else {
      throw HT_Error_Defined_Runtime(stmt.id.lexeme);
    }
  }

  /// Fetch the value of a static member from this class.
  @override
  dynamic fetch(String varName, {String? from}) {
    if (fullName.startsWith(HT_Lexicon.underscore) && !from!.startsWith(fullName)) {
      throw HT_Error_PrivateDecl(fullName);
    } else if (varName.startsWith(HT_Lexicon.underscore) && !from!.startsWith(fullName)) {
      throw HT_Error_PrivateMember(varName);
    }
    var getter = '${HT_Lexicon.getter}$varName';
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
        HT_Function func = defs[getter]!.value;
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

    throw HT_Error_Undefined(varName);
  }

  /// Assign a value to a static member of this class.
  @override
  void assign(String varName, dynamic value, {String? from}) {
    if (fullName.startsWith(HT_Lexicon.underscore) && !from!.startsWith(fullName)) {
      throw HT_Error_PrivateDecl(fullName);
    } else if (varName.startsWith(HT_Lexicon.underscore) && !from!.startsWith(fullName)) {
      throw HT_Error_PrivateMember(varName);
    }

    var setter = '${HT_Lexicon.setter}$varName';
    if (defs.containsKey(varName)) {
      var decl_type = defs[varName]!.declType;
      var var_type = HT_TypeOf(value);
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
        throw HT_Error_Immutable(varName);
      }
      throw HT_Error_Type(varName, var_type.toString(), decl_type.toString());
    } else if (defs.containsKey(setter)) {
      HT_Function setterFunc = defs[setter]!.value;
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
          externSetterFunc(value);
          return;
        }
      }
    }

    if (closure != null) {
      closure!.assign(varName, value, from: from);
      return;
    }

    throw HT_Error_Undefined(varName);
  }

  /// Create a instance from this class.
  /// TODO：对象初始化时从父类逐个调用构造函数
  HT_Instance createInstance(HT_ASTInterpreter interpreter, int? line, int? column,
      {List<HT_TypeId> typeArgs = const [],
      String? constructorName,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {}}) {
    var instance = HT_Instance(this, interpreter, typeArgs: typeArgs.sublist(0, typeParams.length));

    var save = interpreter.curNamespace;
    interpreter.curNamespace = instance;
    for (final decl in variables.values) {
      dynamic value;
      if (decl.initializer != null) {
        value = interpreter.evaluateExpr(decl.initializer!);
      }
      instance.define(decl.id.lexeme, declType: decl.declType, value: value);
    }
    interpreter.curNamespace = save;

    constructorName ??= id;
    var constructor = fetch(constructorName, from: fullName);

    if (constructor is HT_Function) {
      constructor.call(positionalArgs: positionalArgs, namedArgs: namedArgs, instance: instance);
    }

    return instance;
  }
}

/// [HT_Instance] is the Dart implementation of the instance instance in Hetu.
class HT_Instance extends HT_Namespace {
  static var instanceIndex = 0;

  final bool isExtern;

  final HT_Class klass;

  late final HT_TypeId _typeid;
  @override
  HT_TypeId get typeid => _typeid;

  HT_Instance(this.klass, HT_ASTInterpreter interpreter, {List<HT_TypeId> typeArgs = const [], this.isExtern = false})
      : super(interpreter, id: '${HT_Lexicon.instance}${instanceIndex++}', closure: klass) {
    _typeid = HT_TypeId(klass.id, arguments: typeArgs = const []);
    define(HT_Lexicon.THIS, declType: typeid, value: this);
  }

  @override
  String toString() => '${HT_Lexicon.instanceOf}$typeid';

  @override
  bool contains(String varName) => defs.containsKey(varName) || defs.containsKey('${HT_Lexicon.getter}$varName');

  @override
  dynamic fetch(String varName, {String? from}) {
    if (fullName.startsWith(HT_Lexicon.underscore) && !from!.startsWith(fullName)) {
      throw HT_Error_PrivateDecl(fullName);
    } else if (varName.startsWith(HT_Lexicon.underscore) && !from!.startsWith(fullName)) {
      throw HT_Error_PrivateMember(varName);
    }

    if (defs.containsKey(varName)) {
      return defs[varName]!.value;
    } else {
      var getter = '${HT_Lexicon.getter}$varName';
      if (klass.contains(getter)) {
        HT_Function method = klass.fetch(getter, from: klass.fullName);
        if (!method.funcStmt.isStatic) {
          return method.call(instance: this);
        }
      } else {
        final HT_Function method = klass.fetch(varName, from: klass.fullName);
        if (!method.funcStmt.isStatic) {
          method.declContext = this;
          return method;
        }
      }
    }

    throw HT_Error_UndefinedMember(varName, typeid.toString());
  }

  @override
  void assign(String varName, dynamic value, {String? from}) {
    if (fullName.startsWith(HT_Lexicon.underscore) && !from!.startsWith(fullName)) {
      throw HT_Error_PrivateDecl(fullName);
    } else if (varName.startsWith(HT_Lexicon.underscore) && !from!.startsWith(fullName)) {
      throw HT_Error_PrivateMember(varName);
    }

    if (defs.containsKey(varName)) {
      var decl_type = defs[varName]!.declType;
      var var_type = HT_TypeOf(value);
      if (var_type.isA(decl_type)) {
        if (!defs[varName]!.isImmutable) {
          defs[varName]!.value = value;
          return;
        }
        throw HT_Error_Immutable(varName);
      }
      throw HT_Error_Type(varName, var_type.toString(), decl_type.toString());
    } else {
      var setter = '${HT_Lexicon.setter}$varName';
      if (klass.contains(setter)) {
        HT_Function? method = klass.fetch(setter, from: klass.fullName);
        if ((method != null) && (!method.funcStmt.isStatic)) {
          method.call(positionalArgs: [value], instance: this);
          return;
        }
      }
    }

    throw HT_Error_Undefined(varName);
  }

  dynamic invoke(String methodName,
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}}) {
    HT_Function? method = klass.fetch(methodName, from: klass.fullName);
    if ((method != null) && (!method.funcStmt.isStatic)) {
      return method.call(positionalArgs: positionalArgs, namedArgs: namedArgs, instance: this);
    }

    throw HT_Error_Undefined(methodName);
  }
}
