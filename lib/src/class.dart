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
  } else {
    return HS_Common.UnknownType;
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

  List<VarStmt> variables = [];
  Map<String, HS_FuncObj> methods = {};

  HS_Class(this.name, {String superClassName, List<VarStmt> variables, List<FuncStmt> methods})
      : super(blockName: name) {
    if ((superClassName == null) && (name != HS_Common.Object)) superClassName = HS_Common.Object;
    if (superClassName != null) superClass = globalInterpreter.fetchGlobal(superClassName);

    for (var variable in variables) {
      if (variable.isStatic) {
        dynamic value;
        if (variable.initializer != null) {
          value = globalInterpreter.evaluateExpr(variable.initializer);
        } else if (variable.isExtern) {
          value = globalInterpreter.fetchExternal('${name}${HS_Common.Dot}${variable.name.lexeme}');
        }

        if (variable.typename.lexeme == HS_Common.Dynamic) {
          define(variable.name.lexeme, variable.typename.lexeme, value: value);
        } else if (variable.typename.lexeme == HS_Common.Var) {
          // 如果用了var关键字，则从初始化表达式推断变量类型
          if (value != null) {
            define(variable.name.lexeme, HS_TypeOf(value), value: value);
          } else {
            define(variable.name.lexeme, HS_Common.Dynamic);
          }
        } else {
          // 接下来define函数会判断类型是否符合声明
          define(variable.name.lexeme, variable.typename.lexeme, value: value);
        }
      } else {
        this.variables.add(variable);
      }
    }

    for (var method in methods) {
      dynamic func;
      if (method.isExtern) {
        var externFunc = globalInterpreter.fetchExternal('${name}${HS_Common.Dot}${method.internalName}');
        func = HS_FuncObj(method.internalName,
            className: name, funcStmt: method, extern: externFunc, functype: method.functype, arity: method.arity);
      } else {
        Namespace closure;
        if (method.isStatic) {
          // 静态函数外层是类本身
          closure = this;
        } else {
          // 成员函数外层是实例，在某个实例取出函数的时候才绑定到那个实例上
          closure = null;
        }
        func = HS_FuncObj(method.internalName,
            className: name, funcStmt: method, closure: closure, functype: method.functype, arity: method.arity);
      }
      if (method.isStatic) {
        define(method.internalName, HS_Common.FunctionObj, value: func);
      } else {
        this.methods[method.internalName] = func;
      }
    }
  }

  dynamic fetchMethod(String name, {String from = HS_Common.Global}) {
    var getter = '${HS_Common.Getter}$name';
    if (methods.containsKey(name)) {
      if ((blockName == from) || (!name.startsWith(HS_Common.Private))) {
        return methods[name];
      }
      throw HSErr_Private(name);
    } else if (methods.containsKey(getter)) {
      return methods[getter];
    }

    if (superClass != null) {
      return superClass.fetchMethod(name);
    }

    throw HSErr_UndefinedMember(name, this.name);
  }

  @override
  dynamic fetch(String name, {bool error = true, String from = HS_Common.Global}) {
    var getter = '${HS_Common.Getter}$name';
    if (defs.containsKey(name)) {
      if ((blockName == from) || (!name.startsWith(HS_Common.Private))) {
        return defs[name].value;
      }
      throw HSErr_Private(name);
    } else if (defs.containsKey(getter)) {
      if ((blockName == from) || (!name.startsWith(HS_Common.Private))) {
        HS_FuncObj func = defs[getter].value;
        return func.call([]);
      }
      throw HSErr_Private(name);
    }

    if (superClass != null) {
      return superClass.fetch(name, error: error, from: superClass.blockName);
    }

    if (error) throw HSErr_Undefined(name);
    return null;
  }

  @override
  dynamic assign(String varname, dynamic value, {String from = HS_Common.Global}) {
    var setter = '${HS_Common.Setter}$varname';
    if (defs.containsKey(varname)) {
      if ((blockName == from) || (!varname.startsWith(HS_Common.Private))) {
        var vartype = defs[varname].type;
        if ((vartype == HS_Common.Dynamic) || (vartype == HS_TypeOf(value))) {
          defs[varname].value = value;
        } else {
          throw HSErr_Type(HS_TypeOf(value), vartype);
        }
      } else {
        throw HSErr_Private(varname);
      }
    } else if (defs.containsKey(setter)) {
      if ((blockName == from) || (!varname.startsWith(HS_Common.Private))) {
        HS_FuncObj setter_func = defs[setter].value;
        setter_func.call([value]);
      } else {
        throw HSErr_Private(varname);
      }
    } else if (superClass != null) {
      superClass.assign(varname, value, from: from);
    } else {
      throw HSErr_Undefined(varname);
    }
  }

  @override
  void assignAt(int distance, String name, dynamic value, {String from = HS_Common.Global}) {}

  HS_Instance createInstance({String constructorName, List<dynamic> args}) {
    var instance = HS_Instance(name);

    for (var decl in variables) {
      dynamic value;
      if (decl.initializer != null) value = globalInterpreter.evaluateExpr(decl.initializer);

      if (decl.typename.lexeme == HS_Common.Dynamic) {
        instance.define(decl.name.lexeme, decl.typename.lexeme, value: value);
      } else if (decl.typename.lexeme == HS_Common.Var) {
        // 如果用了var关键字，则从初始化表达式推断变量类型
        if (value != null) {
          instance.define(decl.name.lexeme, HS_TypeOf(value), value: value);
        } else {
          instance.define(decl.name.lexeme, HS_Common.Dynamic);
        }
      } else {
        // 接下来define函数会判断类型是否符合声明
        instance.define(decl.name.lexeme, decl.typename.lexeme, value: value);
      }
    }

    HS_FuncObj constructorFunction;
    constructorName ??= name;

    try {
      constructorFunction = fetchMethod(constructorName);
    } catch (e) {
      if (e is! HSErr_Undefined) {
        throw e;
      }
    }

    if (constructorFunction is HS_FuncObj) {
      constructorFunction.bind(instance).call(args);
    }

    return instance;
  }
}

class HS_Instance extends Namespace {
  String get type => _class.name;

  @override
  String toString() => '${HS_Common.InstanceName}[${_class.name}]';

  HS_Class _class;

  HS_Instance(String class_name) : super(blockName: class_name) {
    _class = globalInterpreter.fetchGlobal(class_name);
  }

  @override
  dynamic fetch(String name, {bool error = true, String from = HS_Common.Global}) {
    if (defs.containsKey(name)) {
      if ((blockName == from) || (!name.startsWith(HS_Common.Private))) {
        return defs[name].value;
      }
      throw HSErr_Private(name);
    } else {
      HS_FuncObj method = _class.fetchMethod(name, from: from);
      if (method.functype == FuncStmtType.normal) {
        return method.bind(this);
      } else if (method.functype == FuncStmtType.getter) {
        return method.bind(this).call([]);
      }
    }

    if (error) throw HSErr_UndefinedMember(name, this.type);
  }

  @override
  void assign(String varname, dynamic value, {String from = HS_Common.Global}) {
    if (defs.containsKey(varname)) {
      if ((blockName == from) || (!varname.startsWith(HS_Common.Private))) {
        var vartype = defs[varname].type;
        if ((vartype == HS_Common.Dynamic) || (vartype == HS_TypeOf(value))) {
          defs[varname].value = value;
        } else {
          throw HSErr_Type(HS_TypeOf(value), vartype);
        }
      } else {
        throw HSErr_Private(varname);
      }
    } else {
      throw HSErr_UndefinedMember(varname, _class.name);
    }
  }

  @override
  void assignAt(int distance, String name, dynamic value, {String from = HS_Common.Global}) {}

  dynamic invoke(String name, {List<dynamic> args}) {
    HS_FuncObj method = _class.fetchMethod(name);
    return method.bind(this).call(args);
  }
}
