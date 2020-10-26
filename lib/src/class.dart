import 'package:hetu_script/src/environment.dart';
import 'package:hetu_script/src/interpreter.dart';
import 'package:hetu_script/src/namespace.dart';
import 'package:hetu_script/src/function.dart';
import 'package:hetu_script/src/errors.dart';
import 'package:hetu_script/src/statement.dart';
import 'package:hetu_script/src/value.dart';

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

  String toString() => '${env.lexicon.CLASS} $name';

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
      defs.containsKey('${env.lexicon.getter}$varName') ||
      (superClass == null ? false : superClass.contains(varName)) ||
      (superClass == null ? false : superClass.contains('${env.lexicon.getter}$varName'));

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
    from ??= env.lexicon.globals;
    var getter = '${env.lexicon.getter}$varName';
    if (defs.containsKey(varName)) {
      if (from.startsWith(this.fullName) || !varName.startsWith(env.lexicon.underscore)) {
        return defs[varName].value;
      }
      throw HTErr_Private(varName, line, column, interpreter.curFileName);
    } else if (defs.containsKey(getter)) {
      if (from.startsWith(this.fullName) || !varName.startsWith(env.lexicon.underscore)) {
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
    from ??= env.lexicon.globals;
    var setter = '${env.lexicon.setter}$varName';
    if (defs.containsKey(varName)) {
      var decl_type = defs[varName].typeid;
      var var_type = HT_TypeOf(value);
      if (from.startsWith(this.fullName) || !varName.startsWith(env.lexicon.underscore)) {
        if (var_type.isA(decl_type)) {
          defs[varName].value = value;
          return;
        }
        throw HTErr_Type(varName, var_type.toString(), decl_type.toString(), line, column, interpreter.curFileName);
      }
      throw HTErr_Private(varName, line, column, interpreter.curFileName);
    } else if (defs.containsKey(setter)) {
      if (from.startsWith(this.fullName) || !varName.startsWith(env.lexicon.underscore)) {
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
    for (var decl in variables.values) {
      dynamic value;
      if (decl.initializer != null) {
        value = interpreter.evaluateExpr(decl.initializer);
      }
      instance.define(decl.name.lexeme, interpreter, declType: decl.declType, line: line, column: column, value: value);
    }

    interpreter.curContext = save;

    initterName = env.lexicon.constructor + (initterName == null ? name : initterName);

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
      : super(name: env.lexicon.instance + (_instanceIndex++).toString(), closure: klass) {
    _typeid = HT_Type(klass.name, arguments: typeArgs);

    define(env.lexicon.THIS, interpreter, declType: typeid, value: this);
    //klass = globalInterpreter.fetchGlobal(class_name, line, column, fileName);
  }

  @override
  String toString() => '${env.lexicon.instancePrefix}${typeid}';

  @override
  bool contains(String varName) => defs.containsKey(varName) || defs.containsKey('${env.lexicon.getter}$varName');

  @override
  dynamic fetch(String varName, int line, int column, Interpreter interpreter,
      {bool error = true, String from, bool recursive = true}) {
    from ??= env.lexicon.globals;
    if (defs.containsKey(varName)) {
      if (!varName.startsWith(env.lexicon.underscore)) {
        return defs[varName].value;
      }
      throw HTErr_Private(varName, line, column, interpreter.curFileName);
    } else {
      var getter = '${env.lexicon.getter}$varName';
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

    if (error) throw HTErr_UndefinedMember(varName, this.typeid.toString(), line, column, interpreter.curFileName);
  }

  @override
  void assign(String varName, dynamic value, int line, int column, Interpreter interpreter,
      {bool error = true, String from, bool recursive = true}) {
    from ??= env.lexicon.globals;
    if (defs.containsKey(varName)) {
      var decl_type = defs[varName].typeid;
      var var_type = HT_TypeOf(value);
      if (!varName.startsWith(env.lexicon.underscore)) {
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
      var setter = '${env.lexicon.setter}$varName';
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
