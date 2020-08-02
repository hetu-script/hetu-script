import 'interpreter.dart';
import 'namespace.dart';
import 'common.dart';
import 'function.dart';
import 'errors.dart';
import 'statement.dart';

String HS_TypeOf(dynamic value) {
  if ((value == null) || (value is NullThrownError)) {
    return HS_Common.Null;
  } else if (value is HS_Value) {
    return value.type;
  } else if (value is num) {
    return HS_Common.Num;
  } else if (value is bool) {
    return HS_Common.Bool;
  } else if (value is String) {
    return HS_Common.Str;
  } else if (value is List) {
    return HS_Common.List;
  } else if (value is Map) {
    return HS_Common.Map;
  } else {
    return value.runtimeType.toString();
  }
}

/// [HS_Class]的实例对应河图中的"class"声明
///
/// [HS_Class]继承自命名空间[Namespace]，[HS_Class]中的变量，对应在河图中对应"class"以[static]关键字声明的成员
///
/// 类的方法单独定义在一个表中，通过[fetchMethod]获取
///
/// 类的静态成员定义在所继承的[Namespace]的表中，通过[define]和[fetch]定义和获取
///
/// TODO：对象初始化时从父类逐个调用构造函数
class HS_Class extends Namespace {
  String get type => HS_Common.Class;

  String toString() => '$name';

  final String name;

  HS_Class superClass;

  Map<String, VarStmt> variables = {};
  Map<String, HS_FuncObj> methods = {};

  HS_Class(this.name,
      //int line, int column, String file_name,
      {this.superClass})
      : super(globalInterpreter.curFileName,
            enclosing: globalInterpreter.curContext,
            //line, column, file_name,
            spaceName: name);

  void addVariable(VarStmt stmt) {
    if (!variables.containsKey(stmt.name.lexeme))
      variables[stmt.name.lexeme] = stmt;
    else
      throw HSErr_Defined(name, stmt.name.line, stmt.name.column, globalInterpreter.curFileName);
  }

  void addMethod(String name, HS_FuncObj func, int line, int column, String file_name) {
    if (!methods.containsKey(name))
      methods[name] = func;
    else
      throw HSErr_Defined(name, line, column, file_name);
  }

  dynamic fetchMethod(String name, int line, int column, String file_name,
      {bool error = true, String from = HS_Common.Global}) {
    var getter = '${HS_Common.Getter}$name';
    if (methods.containsKey(name)) {
      if ((spaceName == from) || (!name.startsWith(HS_Common.Underscore))) {
        return methods[name];
      }
      throw HSErr_Private(name, line, column, file_name);
    } else if (methods.containsKey(getter)) {
      return methods[getter];
    }

    if (superClass != null) {
      return superClass.fetchMethod(name, line, column, file_name, error: error);
    }
    if (error) {
      throw HSErr_UndefinedMember(name, this.name, line, column, file_name);
    }
  }

  @override
  dynamic fetch(String name, int line, int column, String file_name,
      {bool error = true, String from = HS_Common.Global}) {
    var getter = '${HS_Common.Getter}$name';
    if (defs.containsKey(name)) {
      if ((spaceName == from) || (!name.startsWith(HS_Common.Underscore))) {
        return defs[name].value;
      }
      throw HSErr_Private(name, line, column, file_name);
    } else if (defs.containsKey(getter)) {
      if ((spaceName == from) || (!name.startsWith(HS_Common.Underscore))) {
        HS_FuncObj func = defs[getter].value;
        return func.call(line, column, file_name, []);
      }
      throw HSErr_Private(name, line, column, file_name);
    }

    if (superClass != null) {
      return superClass.fetch(name, line, column, file_name, error: error, from: superClass.spaceName);
    }

    if (error) throw HSErr_Undefined(name, line, column, file_name);
    return null;
  }

  @override
  dynamic assign(String varname, dynamic value, int line, int column, String file_name,
      {String from = HS_Common.Global}) {
    var setter = '${HS_Common.Setter}$varname';
    if (defs.containsKey(varname)) {
      if ((spaceName == from) || (!varname.startsWith(HS_Common.Underscore))) {
        var vartype = defs[varname].type;
        if ((vartype == HS_Common.Dynamic) || (vartype == HS_TypeOf(value))) {
          defs[varname].value = value;
        } else {
          throw HSErr_Type(HS_TypeOf(value), vartype, line, column, file_name);
        }
      } else {
        throw HSErr_Private(varname, line, column, file_name);
      }
    } else if (defs.containsKey(setter)) {
      if ((spaceName == from) || (!varname.startsWith(HS_Common.Underscore))) {
        HS_FuncObj setter_func = defs[setter].value;
        setter_func.call(line, column, file_name, [value]);
      } else {
        throw HSErr_Private(varname, line, column, file_name);
      }
    } else if (superClass != null) {
      superClass.assign(varname, value, line, column, file_name, from: from);
    } else {
      throw HSErr_Undefined(varname, line, column, file_name);
    }
  }

  @override
  void assignAt(int distance, String name, dynamic value, int line, int column, String file_name,
      {String from = HS_Common.Global}) {}

  HS_Instance createInstance(int line, int column, String file_name, {String constructorName, List<dynamic> args}) {
    var instance = HS_Instance(this);

    for (var decl in variables.values) {
      dynamic value;
      if (decl.initializer != null) value = globalInterpreter.evaluateExpr(decl.initializer);

      if (decl.typename.lexeme == HS_Common.Dynamic) {
        instance.define(decl.name.lexeme, decl.typename.lexeme, line, column, file_name, value: value);
      } else if (decl.typename.lexeme == HS_Common.Var) {
        // 如果用了var关键字，则从初始化表达式推断变量类型
        if (value != null) {
          instance.define(decl.name.lexeme, HS_TypeOf(value), line, column, file_name, value: value);
        } else {
          instance.define(decl.name.lexeme, HS_Common.Dynamic, line, column, file_name);
        }
      } else {
        // 接下来define函数会判断类型是否符合声明
        instance.define(decl.name.lexeme, decl.typename.lexeme, line, column, file_name, value: value);
      }
    }

    HS_FuncObj constructorFunction;
    constructorName ??= HS_Common.Constructor + name;

    constructorFunction = fetchMethod(constructorName, line, column, file_name, error: false, from: name);

    if (constructorFunction != null) {
      constructorFunction.bind(instance, line, column, file_name).call(line, column, file_name, args ?? []);
    }

    return instance;
  }
}

class HS_Instance extends Namespace {
  String get type => ofClass.name;

  @override
  String toString() => '${HS_Common.InstanceName}[${ofClass.name}]';

  HS_Class ofClass;

  HS_Instance(this.ofClass) //, int line, int column, String file_name)
      : super(globalInterpreter.curFileName,
            //line, column, file_name,

            spaceName: ofClass.name) {
    //ofClass = globalInterpreter.fetchGlobal(class_name, line, column, file_name);
  }

  @override
  dynamic fetch(String name, int line, int column, String file_name,
      {bool error = true, String from = HS_Common.Global}) {
    if (defs.containsKey(name)) {
      if ((spaceName == from) || (!name.startsWith(HS_Common.Underscore))) {
        return defs[name].value;
      }
      throw HSErr_Private(name, line, column, file_name);
    } else {
      HS_FuncObj method = ofClass.fetchMethod(name, line, column, file_name, error: false, from: from);
      if (method != null) {
        if (method.functype == FuncStmtType.getter) {
          return method.bind(this, line, column, file_name).call(line, column, file_name, []);
        } else {
          return method.bind(this, line, column, file_name);
        }
      }
    }

    if (error) throw HSErr_UndefinedMember(name, this.type, line, column, file_name);
  }

  @override
  void assign(String varname, dynamic value, int line, int column, String file_name, {String from = HS_Common.Global}) {
    var setter = '${HS_Common.Setter}$varname';
    if (defs.containsKey(varname)) {
      if ((spaceName == from) || (!varname.startsWith(HS_Common.Underscore))) {
        var vartype = defs[varname].type;
        if ((vartype == HS_Common.Dynamic) || (vartype == HS_TypeOf(value))) {
          defs[varname].value = value;
        } else {
          throw HSErr_Type(HS_TypeOf(value), vartype, line, column, file_name);
        }
      } else {
        throw HSErr_Private(varname, line, column, file_name);
      }
    } else {
      HS_FuncObj setter_func =
          ofClass.fetchMethod(setter, line, column, file_name, error: false, from: ofClass.spaceName);
      setter_func.bind(this, line, column, file_name).call(line, column, file_name, [value]);
    }
  }

  @override
  void assignAt(int distance, String name, dynamic value, int line, int column, String file_name,
      {String from = HS_Common.Global}) {}

  dynamic invoke(String name, {List<dynamic> args}) {
    HS_FuncObj method = ofClass.fetchMethod(name, null, null, globalInterpreter.curFileName);
    return method
        .bind(this, null, null, globalInterpreter.curFileName)
        .call(null, null, globalInterpreter.curFileName, args ?? []);
  }
}
