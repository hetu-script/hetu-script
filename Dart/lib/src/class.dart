import 'package:hetu_script/hetu.dart';

import 'interpreter.dart';
import 'namespace.dart';
import 'common.dart';
import 'function.dart';
import 'errors.dart';
import 'statement.dart';
import 'value.dart';

/// [HS_Class]的实例对应河图中的"class"声明
///
/// [HS_Class]继承自命名空间[HS_Namespace]，[HS_Class]中的变量，对应在河图中对应"class"以[static]关键字声明的成员
///
/// 类的方法单独定义在一个表中，通过[fetchMethod]获取
///
/// 类的静态成员定义在所继承的[HS_Namespace]的表中，通过[define]和[fetch]定义和获取
///
/// TODO：对象初始化时从父类逐个调用构造函数
class HS_Class extends HS_Namespace {
  List<String> typeParams = [];

  String toString() => '${HS_Common.CLASS} $name';

  HS_Class superClass;

  Map<String, VarStmt> variables = {};
  //Map<String, HS_Function> methods = {};

  HS_Class(String name, {List<String> typeParams, HS_Namespace closure, this.superClass})
      : super(name: name, closure: closure) {
    if (typeParams != null) this.typeParams.addAll(typeParams);
  }

  @override
  bool contains(String varName) =>
      variables.containsKey(varName) ||
      defs.containsKey(varName) ||
      defs.containsKey('${HS_Common.getFun}$varName') ||
      (superClass == null ? false : superClass.contains(varName)) ||
      (superClass == null ? false : superClass.contains('${HS_Common.getFun}$varName'));

  void addVariable(VarStmt stmt) {
    if (!variables.containsKey(stmt.name.lexeme)) {
      variables[stmt.name.lexeme] = stmt;
    } else {
      throw HSErr_Defined(name, stmt.name.line, stmt.name.column, null);
    }
  }

  // void addMethod(String name, HS_FuncObj func, int line, int column, String fileName) {
  //   if (!methods.containsKey(name))
  //     methods[name] = func;
  //   else
  //     throw HSErr_Defined(name, line, column, fileName);
  // }

  // dynamic fetchMethod(String name, int line, int column, String fileName,
  //     {bool error = true, String from = HS_Common.Global}) {
  //   var getter = '${HS_Common.Getter}$name';
  //   if (methods.containsKey(name)) {
  //     if (from.startsWith(from) || (!name.startsWith(HS_Common.Underscore))) {
  //       return methods[name];
  //     }
  //     throw HSErr_Private(name, line, column, fileName);
  //   } else if (methods.containsKey(getter)) {
  //     return methods[getter];
  //   }

  //   // if (superClass is HS_Class) {
  //   //   (closure as HS_Class).fetchMethod(name, line, column, fileName, error: error);
  //   // }

  //   if (error) {
  //     throw HSErr_UndefinedMember(name, this.name, line, column, fileName);
  //   }
  // }

  @override
  dynamic fetch(String varName, int line, int column, Interpreter interpreter,
      {bool error = true, String from = HS_Common.global, bool recursive = true}) {
    var getter = '${HS_Common.getFun}$varName';
    if (defs.containsKey(varName)) {
      if (from.startsWith(this.fullName) || !varName.startsWith(HS_Common.underscore)) {
        return defs[varName].value;
      }
      throw HSErr_Private(varName, line, column, interpreter.curFileName);
    } else if (defs.containsKey(getter)) {
      if (from.startsWith(this.fullName) || !varName.startsWith(HS_Common.underscore)) {
        HS_Function func = defs[getter].value;
        return func.call(interpreter, line, column, []);
      }
      throw HSErr_Private(varName, line, column, interpreter.curFileName);
    } else if ((superClass != null) && (superClass.contains(varName))) {
      return superClass.fetch(varName, line, column, interpreter, error: error, from: closure.fullName);
    }

    if (closure != null) {
      return closure.fetch(varName, line, column, interpreter, error: error, from: closure.fullName);
    }

    if (error) throw HSErr_Undefined(varName, line, column, interpreter.curFileName);
    return null;
  }

  @override
  void assign(String varName, dynamic value, int line, int column, Interpreter interpreter,
      {bool error = true, String from = HS_Common.global, bool recursive = true}) {
    var setter = '${HS_Common.setFun}$varName';
    if (defs.containsKey(varName)) {
      var decl_type = defs[varName].typeid;
      var var_type = HS_TypeOf(value);
      if (from.startsWith(this.fullName) || !varName.startsWith(HS_Common.underscore)) {
        if (var_type.isA(decl_type)) {
          defs[varName].value = value;
          return;
        }
        throw HSErr_Type(varName, var_type.toString(), decl_type.toString(), line, column, interpreter.curFileName);
      }
      throw HSErr_Private(varName, line, column, interpreter.curFileName);
    } else if (defs.containsKey(setter)) {
      if (from.startsWith(this.fullName) || !varName.startsWith(HS_Common.underscore)) {
        HS_Function setter_func = defs[setter].value;
        setter_func.call(interpreter, line, column, [value]);
        return;
      }
      throw HSErr_Private(varName, line, column, interpreter.curFileName);
    }

    if (closure != null) {
      closure.assign(varName, value, line, column, interpreter, from: from);
      return;
    }

    if (error) throw HSErr_Undefined(varName, line, column, interpreter.curFileName);
  }

  HS_Instance createInstance(Interpreter interpreter, int line, int column, HS_Namespace closure,
      {List<HS_Type> typeArgs, String initterName, List<dynamic> args}) {
    var instance = HS_Instance(this, typeArgs: typeArgs);

    var save = interpreter.curContext;
    interpreter.curContext = instance;
    for (var decl in variables.values) {
      dynamic value;
      if (decl.initializer != null) {
        value = interpreter.evaluateExpr(decl.initializer);
      }

      if (decl.declType != null) {
        instance.define(decl.name.lexeme, decl.declType, line, column, interpreter, value: value);
      } else {
        // 从初始化表达式推断变量类型
        if (value != null) {
          instance.define(decl.name.lexeme, HS_TypeOf(value), line, column, interpreter, value: value);
        } else {
          instance.define(decl.name.lexeme, HS_Type(), line, column, interpreter);
        }
      }
    }

    interpreter.curContext = save;

    initterName = HS_Common.constructFun + (initterName == null ? name : initterName);

    var constructor = fetch(initterName, line, column, interpreter, error: false, from: name);

    if (constructor is HS_Function) {
      constructor.bind(instance, line, column, interpreter).call(interpreter, line, column, args ?? []);
    }

    return instance;
  }
}

class HS_Instance extends HS_Namespace {
  final List<HS_Type> typeArgs = [];

  static int _instanceIndex = 0;

  final HS_Class klass;

  HS_Type _typeid;
  HS_Type get typeid => _typeid;

  HS_Instance(this.klass, {List<HS_Type> typeArgs})
      : super(name: HS_Common.instance + (_instanceIndex++).toString(), closure: klass) {
    _typeid = HS_Type(name: klass.name, arguments: typeArgs);

    define(HS_Common.THIS, typeid, null, null, null, value: this);
    //klass = globalInterpreter.fetchGlobal(class_name, line, column, fileName);
  }

  @override
  String toString() => '${HS_Common.instancePrefix}${typeid}';

  @override
  bool contains(String varName) => defs.containsKey(varName) || defs.containsKey('${HS_Common.getFun}$varName');

  @override
  dynamic fetch(String varName, int line, int column, Interpreter interpreter,
      {bool error = true, String from = HS_Common.global, bool recursive = true}) {
    if (defs.containsKey(varName)) {
      if (!varName.startsWith(HS_Common.underscore)) {
        return defs[varName].value;
      }
      throw HSErr_Private(varName, line, column, interpreter.curFileName);
    } else {
      var getter = '${HS_Common.getFun}$varName';
      if (klass.contains(getter)) {
        HS_Function method = klass.fetch(getter, line, column, interpreter, error: false, from: klass.fullName);
        if ((method != null) && (!method.funcStmt.isStatic)) {
          return method.bind(this, line, column, interpreter).call(interpreter, line, column, []);
        }
      } else if (klass.contains(varName)) {
        HS_Function method = klass.fetch(varName, line, column, interpreter, error: false, from: klass.fullName);
        if ((method != null) && (!method.funcStmt.isStatic)) {
          return method.bind(this, line, column, interpreter);
        }
      }
    }

    if (error) throw HSErr_UndefinedMember(varName, this.typeid.toString(), line, column, interpreter.curFileName);
  }

  @override
  void assign(String varName, dynamic value, int line, int column, Interpreter interpreter,
      {bool error = true, String from = HS_Common.global, bool recursive = true}) {
    if (defs.containsKey(varName)) {
      var decl_type = defs[varName].typeid;
      var var_type = HS_TypeOf(value);
      if (!varName.startsWith(HS_Common.underscore)) {
        if (var_type.isA(decl_type)) {
          if (defs[varName].mutable) {
            defs[varName].value = value;
            return;
          }
          throw HSErr_Mutable(varName, line, column, interpreter.curFileName);
        }
        throw HSErr_Type(varName, var_type.toString(), decl_type.toString(), line, column, interpreter.curFileName);
      }
      throw HSErr_Private(varName, line, column, interpreter.curFileName);
    } else {
      var setter = '${HS_Common.setFun}$varName';
      if (klass.contains(setter)) {
        HS_Function method = klass.fetch(setter, line, column, interpreter, error: false, from: klass.fullName);
        if ((method != null) && (!method.funcStmt.isStatic)) {
          method.bind(this, line, column, interpreter).call(interpreter, line, column, [value]);
          return;
        }
      }
    }

    if (error) throw HSErr_Undefined(varName, line, column, interpreter.curFileName);
  }

  dynamic invoke(String methodName, int line, int column, Interpreter interpreter,
      {bool error = true, List<dynamic> args}) {
    HS_Function method = klass.fetch(methodName, null, null, interpreter, from: klass.fullName);
    if ((method != null) && (!method.funcStmt.isStatic)) {
      return method.bind(this, line, column, interpreter).call(interpreter, null, null, args ?? []);
    }

    if (error) throw HSErr_Undefined(methodName, line, column, interpreter.curFileName);
  }
}
