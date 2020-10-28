import 'lexicon.dart';
import 'interpreter.dart';
import 'namespace.dart';
import 'function.dart';
import 'errors.dart';
import 'statement.dart';
import 'value.dart';

/// [HT_Class]的实例对应河图中的"class"声明
///
/// [HT_Class]继承自命名空间[HT_Namespace]，[HT_Class]中的变量，对应在河图中对应"class"以[static]关键字声明的成员
///
/// 类的方法单独定义在一个表中，通过[fetchMethod]获取
///
/// 类的静态成员定义在所继承的[HT_Namespace]的表中，通过[define]和[fetch]定义和获取
///
/// TODO：对象初始化时从父类逐个调用构造函数
class HT_Class extends HT_Namespace {
  List<String> typeParams = [];

  @override
  String toString() => '${HT_Lexicon.CLASS} $name';

  HT_Class superClass;

  Map<String, VarDeclStmt> variables = {};
  //Map<String, HT_Function> methods = {};

  HT_Class(String name, {List<String> typeParams, HT_Namespace closure, this.superClass})
      : super(name: name, closure: closure) {
    if (typeParams != null) this.typeParams.addAll(typeParams);
  }

  @override
  bool contains(String varName) =>
      variables.containsKey(varName) ||
      defs.containsKey(varName) ||
      defs.containsKey('${HT_Lexicon.getter}$varName') ||
      (superClass == null ? false : superClass.contains(varName)) ||
      (superClass == null ? false : superClass.contains('${HT_Lexicon.getter}$varName'));

  void addVariable(VarDeclStmt stmt) {
    if (!variables.containsKey(stmt.name.lexeme)) {
      variables[stmt.name.lexeme] = stmt;
    } else {
      throw HTErr_Defined(name, stmt.name.line, stmt.name.column, null);
    }
  }

  @override
  dynamic fetch(String varName, int line, int column, Interpreter interpreter,
      {bool error = true, String from, bool recursive = true}) {
    from ??= HT_Lexicon.globals;
    var getter = '${HT_Lexicon.getter}$varName';
    if (defs.containsKey(varName)) {
      if (from.startsWith(fullName) || !varName.startsWith(HT_Lexicon.underscore)) {
        return defs[varName].value;
      }
      throw HTErr_Private(varName, line, column, interpreter.curFileName);
    } else if (defs.containsKey(getter)) {
      if (from.startsWith(fullName) || !varName.startsWith(HT_Lexicon.underscore)) {
        HT_Function func = defs[getter].value;
        return func.call(interpreter, line, column, []);
      }
      throw HTErr_Private(varName, line, column, interpreter.curFileName);
    } else if ((superClass != null) && (superClass.contains(varName))) {
      return superClass.fetch(varName, line, column, interpreter, error: error, from: closure.fullName);
    }

    if (closure != null) {
      return closure.fetch(varName, line, column, interpreter, error: error, from: closure.fullName);
    }

    if (error) throw HTErr_Undefined(varName, line, column, interpreter.curFileName);
    return null;
  }

  @override
  void assign(String varName, dynamic value, int line, int column, Interpreter interpreter,
      {bool error = true, String from, bool recursive = true}) {
    from ??= HT_Lexicon.globals;
    var setter = '${HT_Lexicon.setter}$varName';
    if (defs.containsKey(varName)) {
      var decl_type = defs[varName].typeid;
      var var_type = HT_TypeOf(value);
      if (from.startsWith(fullName) || !varName.startsWith(HT_Lexicon.underscore)) {
        if (var_type.isA(decl_type)) {
          defs[varName].value = value;
          return;
        }
        throw HTErr_Type(varName, var_type.toString(), decl_type.toString(), line, column, interpreter.curFileName);
      }
      throw HTErr_Private(varName, line, column, interpreter.curFileName);
    } else if (defs.containsKey(setter)) {
      if (from.startsWith(fullName) || !varName.startsWith(HT_Lexicon.underscore)) {
        HT_Function setter_func = defs[setter].value;
        setter_func.call(interpreter, line, column, [value]);
        return;
      }
      throw HTErr_Private(varName, line, column, interpreter.curFileName);
    }

    if (closure != null) {
      closure.assign(varName, value, line, column, interpreter, from: from);
      return;
    }

    if (error) throw HTErr_Undefined(varName, line, column, interpreter.curFileName);
  }

  HT_Instance createInstance(Interpreter interpreter, int line, int column, HT_Namespace closure,
      {List<HT_Type> typeArgs, String initterName, List<dynamic> args}) {
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

    initterName = HT_Lexicon.constructor + (initterName ?? name);

    var constructor = fetch(initterName, line, column, interpreter, error: false, from: name);

    if (constructor is HT_Function) {
      constructor.call(interpreter, line, column, args ?? [], instance: instance);
    }

    return instance;
  }
}

class HT_Instance extends HT_Namespace {
  final List<HT_Type> typeArgs = [];

  static int _instanceIndex = 0;

  final HT_Class klass;

  HT_Type _typeid;
  HT_Type get typeid => _typeid;

  HT_Instance(Interpreter interpreter, this.klass, {List<HT_Type> typeArgs})
      : super(name: HT_Lexicon.instance + (_instanceIndex++).toString(), closure: klass) {
    _typeid = HT_Type(klass.name, arguments: typeArgs);

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
      if (!varName.startsWith(HT_Lexicon.underscore)) {
        return defs[varName].value;
      }
      throw HTErr_Private(varName, line, column, interpreter.curFileName);
    } else {
      var getter = '${HT_Lexicon.getter}$varName';
      if (klass.contains(getter)) {
        HT_Function method = klass.fetch(getter, line, column, interpreter, error: false, from: klass.fullName);
        if ((method != null) && (!method.funcStmt.isStatic)) {
          return method.call(interpreter, line, column, [], instance: this);
        }
      } else if (klass.contains(varName)) {
        HT_Function method = klass.fetch(varName, line, column, interpreter, error: false, from: klass.fullName);
        if ((method != null) && (!method.funcStmt.isStatic)) {
          return method;
        }
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
      if (!varName.startsWith(HT_Lexicon.underscore)) {
        if (var_type.isA(decl_type)) {
          if (defs[varName].isMutable) {
            defs[varName].value = value;
            return;
          }
          throw HTErr_Mutable(varName, line, column, interpreter.curFileName);
        }
        throw HTErr_Type(varName, var_type.toString(), decl_type.toString(), line, column, interpreter.curFileName);
      }
      throw HTErr_Private(varName, line, column, interpreter.curFileName);
    } else {
      var setter = '${HT_Lexicon.setter}$varName';
      if (klass.contains(setter)) {
        HT_Function method = klass.fetch(setter, line, column, interpreter, error: false, from: klass.fullName);
        if ((method != null) && (!method.funcStmt.isStatic)) {
          method.call(interpreter, line, column, [value], instance: this);
          return;
        }
      }
    }

    if (error) throw HTErr_Undefined(varName, line, column, interpreter.curFileName);
  }

  dynamic invoke(String methodName, int line, int column, Interpreter interpreter,
      {bool error = true, List<dynamic> args}) {
    HT_Function method = klass.fetch(methodName, null, null, interpreter, from: klass.fullName);
    if ((method != null) && (!method.funcStmt.isStatic)) {
      return method.call(interpreter, null, null, args ?? [], instance: this);
    }

    if (error) throw HTErr_Undefined(methodName, line, column, interpreter.curFileName);
  }
}
