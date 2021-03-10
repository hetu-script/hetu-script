import 'lexicon.dart';
import 'interpreter.dart';
import 'namespace.dart';
import 'function.dart';
import 'errors.dart';
import 'statement.dart';
import 'value.dart';

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
  /// The type parameters of the class.
  List<String> typeParams = [];

  @override
  String toString() => '${HT_Lexicon.CLASS} $identifier';

  /// Super class of this class
  ///
  /// If a class is not extends from any super class, then it is the child of class `Object`
  HT_Class superClass;

  /// The instance members defined in class definition.
  Map<String, VarDeclStmt> variables = {};

  /// Create a class object.
  ///
  /// [name] : the class name
  ///
  /// [typeParams] : the type parameters defined after class name.
  ///
  /// [closure] : the outer namespace of the class declaration,
  /// normally the global namespace of the interpreter.
  ///
  /// [superClass] : super class of this class.
  HT_Class(String name, this.superClass, {List<String> typeParams, HT_Namespace closure})
      : super(name: name, closure: closure) {
    if (typeParams != null) this.typeParams.addAll(typeParams);
  }

  /// Wether the class contains a static member, will also check super class.
  @override
  bool contains(String varName) =>
      defs.containsKey(varName) ||
      defs.containsKey('${HT_Lexicon.getter}$varName') ||
      ((superClass?.contains(varName)) ?? false) ||
      ((superClass?.contains('${HT_Lexicon.getter}$varName')) ?? false);

  /// Add a instance variable declaration to this class.
  void addVariable(VarDeclStmt stmt) {
    if (!variables.containsKey(stmt.name.lexeme)) {
      variables[stmt.name.lexeme] = stmt;
    } else {
      throw HTErr_Defined(stmt.name.lexeme, stmt.name.line, stmt.name.column, null);
    }
  }

  /// Fetch the value of a static member from this class.
  @override
  dynamic fetch(String varName, int line, int column, Interpreter interpreter,
      {bool error = true, String from, bool recursive = true}) {
    from ??= HT_Lexicon.globals;
    var getter = '${HT_Lexicon.getter}$varName';
    if (defs.containsKey(varName)) {
      if (fullName.startsWith(HT_Lexicon.underscore) && !from.startsWith(fullName)) {
        throw HTErr_PrivateDecl(fullName, line, column, interpreter.curFileName);
      } else if (varName.startsWith(HT_Lexicon.underscore) && !from.startsWith(fullName)) {
        throw HTErr_PrivateMember(varName, line, column, interpreter.curFileName);
      }
      return defs[varName].value;
    } else if (defs.containsKey(getter)) {
      if (fullName.startsWith(HT_Lexicon.underscore) && !from.startsWith(fullName)) {
        throw HTErr_PrivateDecl(fullName, line, column, interpreter.curFileName);
      } else if (varName.startsWith(HT_Lexicon.underscore) && !from.startsWith(fullName)) {
        throw HTErr_PrivateMember(varName, line, column, interpreter.curFileName);
      }
      HT_Function func = defs[getter].value;
      return func.call(interpreter, line, column);
    }
    //  else if (defs.containsKey(method)) {
    //   if (fullName.startsWith(HT_Lexicon.underscore) && !from.startsWith(fullName)) {
    //     throw HTErr_PrivateDecl(fullName, line, column, interpreter.curFileName);
    //   } else if (varName.startsWith(HT_Lexicon.underscore) && !from.startsWith(fullName)) {
    //     throw HTErr_PrivateMember(varName, line, column, interpreter.curFileName);
    //   }
    //   return defs[method].value;
    // }
    else if (superClass.contains(varName)) {
      return superClass.fetch(varName, line, column, interpreter, error: error, from: superClass.fullName);
    }

    if (closure != null) {
      return closure.fetch(varName, line, column, interpreter, error: error, from: closure.fullName);
    }

    if (error) throw HTErr_Undefined(varName, line, column, interpreter.curFileName);
    return null;
  }

  /// Assign a value to a static member of this class.
  @override
  void assign(String varName, dynamic value, int line, int column, Interpreter interpreter,
      {bool error = true, String from, bool recursive = true}) {
    from ??= HT_Lexicon.globals;
    var setter = '${HT_Lexicon.setter}$varName';
    if (defs.containsKey(varName)) {
      var decl_type = defs[varName].typeid;
      var var_type = HT_TypeOf(value);
      if (from.startsWith(fullName) ||
          (!fullName.startsWith(HT_Lexicon.underscore) && !varName.startsWith(HT_Lexicon.underscore))) {
        if (var_type.isA(decl_type)) {
          defs[varName].value = value;
          return;
        }
        throw HTErr_Type(varName, var_type.toString(), decl_type.toString(), line, column, interpreter.curFileName);
      }
      throw HTErr_PrivateMember(varName, line, column, interpreter.curFileName);
    } else if (defs.containsKey(setter)) {
      if (from.startsWith(fullName) ||
          (!fullName.startsWith(HT_Lexicon.underscore) && !varName.startsWith(HT_Lexicon.underscore))) {
        HT_Function setter_func = defs[setter].value;
        setter_func.call(interpreter, line, column, positionalArgs: [value]);
        return;
      }
      throw HTErr_PrivateMember(varName, line, column, interpreter.curFileName);
    }

    if (closure != null) {
      closure.assign(varName, value, line, column, interpreter, from: from);
      return;
    }

    if (error) throw HTErr_Undefined(varName, line, column, interpreter.curFileName);
  }

  /// Create a instance from this class.
  /// TODO：对象初始化时从父类逐个调用构造函数
  HT_Instance createInstance(Interpreter interpreter, int line, int column, HT_Namespace closure,
      {List<HT_Type> typeArgs, String constructorName, List<dynamic> positionalArgs, Map<String, dynamic> namedArgs}) {
    var instance = HT_Instance(interpreter, this, typeArgs: typeArgs?.sublist(0, typeParams.length));

    var save = interpreter.curContext;
    interpreter.curContext = instance;
    for (final decl in variables.values) {
      dynamic value;
      if (decl.initializer != null) {
        value = interpreter.evaluateExpr(decl.initializer);
      }
      instance.define(decl.name.lexeme, interpreter, declType: decl.declType, line: line, column: column, value: value);
    }

    interpreter.curContext = save;

    constructorName ??= identifier;

    var constructor = fetch(constructorName, line, column, interpreter, error: false, from: identifier);

    if (constructor is HT_Function) {
      constructor.call(interpreter, line, column,
          positionalArgs: positionalArgs, namedArgs: namedArgs, instance: instance);
    }

    return instance;
  }
}

/// [HT_Instance] is the Dart implementation of the object instance in Hetu.
class HT_Instance extends HT_Namespace {
  final List<HT_Type> typeArgs = [];

  static int _instanceIndex = 0;

  final HT_Class klass;

  HT_Type _typeid;
  HT_Type get typeid => _typeid;

  HT_Instance(Interpreter interpreter, this.klass, {List<HT_Type> typeArgs = const []})
      : super(name: HT_Lexicon.instance + (_instanceIndex++).toString(), closure: klass) {
    _typeid = HT_Type(klass.identifier, arguments: typeArgs = const []);

    define(HT_Lexicon.THIS, interpreter, declType: typeid, value: this);
    //klass = globalInterpreter.fetchGlobal(class_name, line, column, fileName);
  }

  @override
  String toString() => '${HT_Lexicon.instancePrefix}${typeid}';

  @override
  bool contains(String varName) => defs.containsKey(varName) || defs.containsKey('${HT_Lexicon.getter}$varName');

  @override
  dynamic fetch(String varName, int line, int column, Interpreter interpreter,
      {bool error = true, String from, bool recursive = true}) {
    from ??= HT_Lexicon.globals;
    if (defs.containsKey(varName)) {
      if (!varName.startsWith(HT_Lexicon.underscore) || from.startsWith(fullName)) {
        return defs[varName].value;
      }
      throw HTErr_PrivateMember(varName, line, column, interpreter.curFileName);
    } else {
      var getter = '${HT_Lexicon.getter}$varName';
      if (klass.contains(getter)) {
        HT_Function method = klass.fetch(getter, line, column, interpreter, error: false, from: klass.fullName);
        if ((method != null) && (!method.funcStmt.isStatic)) {
          return method.call(interpreter, line, column, instance: this);
        }
      } else {
        // var method_name = '${HT_Lexicon.method}$varName';
        // if (klass.contains(method_name)) {
        final method = klass.fetch(varName, line, column, interpreter, error: false, from: klass.fullName);
        if ((method is HT_Function) && (!method.funcStmt.isStatic)) {
          method.declContext = this;
          return method;
        }
        // }
      }
    }

    if (error) throw HTErr_UndefinedMember(varName, typeid.toString(), line, column, interpreter.curFileName);
  }

  @override
  void assign(String varName, dynamic value, int line, int column, Interpreter interpreter,
      {bool error = true, String from, bool recursive = true}) {
    from ??= HT_Lexicon.globals;
    if (defs.containsKey(varName)) {
      var decl_type = defs[varName].typeid;
      var var_type = HT_TypeOf(value);
      if (!varName.startsWith(HT_Lexicon.underscore) || from.startsWith(fullName)) {
        if (var_type.isA(decl_type)) {
          if (defs[varName].isMutable) {
            defs[varName].value = value;
            return;
          }
          throw HTErr_Mutable(varName, line, column, interpreter.curFileName);
        }
        throw HTErr_Type(varName, var_type.toString(), decl_type.toString(), line, column, interpreter.curFileName);
      }
      throw HTErr_PrivateMember(varName, line, column, interpreter.curFileName);
    } else {
      var setter = '${HT_Lexicon.setter}$varName';
      if (klass.contains(setter)) {
        HT_Function method = klass.fetch(setter, line, column, interpreter, error: false, from: klass.fullName);
        if ((method != null) && (!method.funcStmt.isStatic)) {
          method.call(interpreter, line, column, positionalArgs: [value], instance: this);
          return;
        }
      }
    }

    if (error) throw HTErr_Undefined(varName, line, column, interpreter.curFileName);
  }

  dynamic invoke(String methodName, int line, int column, Interpreter interpreter,
      {bool error = true, List<dynamic> positionalArgs, Map<String, dynamic> namedArgs}) {
    HT_Function method = klass.fetch(methodName, null, null, interpreter, from: klass.fullName);
    if ((method != null) && (!method.funcStmt.isStatic)) {
      return method.call(interpreter, null, null, positionalArgs: positionalArgs, namedArgs: namedArgs, instance: this);
    }

    if (error) throw HTErr_Undefined(methodName, line, column, interpreter.curFileName);
  }
}
