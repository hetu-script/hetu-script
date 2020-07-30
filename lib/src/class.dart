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

  List<VarStmt> variables = [];
  Map<String, HS_FuncObj> methods = {};

  HS_Class(this.name,
      //int line, int column, String filename,
      {this.superClass})
      : super(
            //line, column, filename,
            blockName: name);

  void addVariable(VarStmt stmt) => variables.add(stmt);

  void addMethod(String name, HS_FuncObj func) => methods[name] = func;

  dynamic fetchMethod(String name, int line, int column, String filename,
      {bool error = true, String from = HS_Common.Global}) {
    var getter = '${HS_Common.Getter}$name';
    if (methods.containsKey(name)) {
      if ((blockName == from) || (!name.startsWith(HS_Common.Underscore))) {
        return methods[name];
      }
      throw HSErr_Private(name, line, column, filename);
    } else if (methods.containsKey(getter)) {
      return methods[getter];
    }

    if (superClass != null) {
      return superClass.fetchMethod(name, line, column, filename, error: error);
    }
    if (error) {
      throw HSErr_UndefinedMember(name, this.name, line, column, filename);
    }
  }

  @override
  dynamic fetch(String name, int line, int column, String filename,
      {bool error = true, String from = HS_Common.Global}) {
    var getter = '${HS_Common.Getter}$name';
    if (defs.containsKey(name)) {
      if ((blockName == from) || (!name.startsWith(HS_Common.Underscore))) {
        return defs[name].value;
      }
      throw HSErr_Private(name, line, column, filename);
    } else if (defs.containsKey(getter)) {
      if ((blockName == from) || (!name.startsWith(HS_Common.Underscore))) {
        HS_FuncObj func = defs[getter].value;
        return func.call(line, column, filename, []);
      }
      throw HSErr_Private(name, line, column, filename);
    }

    if (superClass != null) {
      return superClass.fetch(name, line, column, filename, error: error, from: superClass.blockName);
    }

    if (error) throw HSErr_Undefined(name, line, column, filename);
    return null;
  }

  @override
  dynamic assign(String varname, dynamic value, int line, int column, String filename,
      {String from = HS_Common.Global}) {
    var setter = '${HS_Common.Setter}$varname';
    if (defs.containsKey(varname)) {
      if ((blockName == from) || (!varname.startsWith(HS_Common.Underscore))) {
        var vartype = defs[varname].type;
        if ((vartype == HS_Common.Dynamic) || (vartype == HS_TypeOf(value))) {
          defs[varname].value = value;
        } else {
          throw HSErr_Type(HS_TypeOf(value), vartype, line, column, filename);
        }
      } else {
        throw HSErr_Private(varname, line, column, filename);
      }
    } else if (defs.containsKey(setter)) {
      if ((blockName == from) || (!varname.startsWith(HS_Common.Underscore))) {
        HS_FuncObj setter_func = defs[setter].value;
        setter_func.call(line, column, filename, [value]);
      } else {
        throw HSErr_Private(varname, line, column, filename);
      }
    } else if (superClass != null) {
      superClass.assign(varname, value, line, column, filename, from: from);
    } else {
      throw HSErr_Undefined(varname, line, column, filename);
    }
  }

  @override
  void assignAt(int distance, String name, dynamic value, int line, int column, String filename,
      {String from = HS_Common.Global}) {}

  HS_Instance createInstance(int line, int column, String filename, {String constructorName, List<dynamic> args}) {
    var instance = HS_Instance(this);

    for (var decl in variables) {
      dynamic value;
      if (decl.initializer != null) value = globalInterpreter.evaluateExpr(decl.initializer);

      if (decl.typename.lexeme == HS_Common.Dynamic) {
        instance.define(decl.name.lexeme, decl.typename.lexeme, line, column, filename, value: value);
      } else if (decl.typename.lexeme == HS_Common.Var) {
        // 如果用了var关键字，则从初始化表达式推断变量类型
        if (value != null) {
          instance.define(decl.name.lexeme, HS_TypeOf(value), line, column, filename, value: value);
        } else {
          instance.define(decl.name.lexeme, HS_Common.Dynamic, line, column, filename);
        }
      } else {
        // 接下来define函数会判断类型是否符合声明
        instance.define(decl.name.lexeme, decl.typename.lexeme, line, column, filename, value: value);
      }
    }

    HS_FuncObj constructorFunction;
    constructorName ??= name;

    constructorFunction = fetchMethod(constructorName, line, column, filename, error: false);

    if (constructorFunction != null) {
      constructorFunction.bind(instance, line, column, filename).call(line, column, filename, args ?? []);
    }

    return instance;
  }
}

class HS_Instance extends Namespace {
  String get type => ofClass.name;

  @override
  String toString() => '${HS_Common.InstanceName}[${ofClass.name}]';

  HS_Class ofClass;

  HS_Instance(this.ofClass) //, int line, int column, String filename)
      : super(
            //line, column, filename,

            blockName: ofClass.name) {
    //ofClass = globalInterpreter.fetchGlobal(class_name, line, column, filename);
  }

  @override
  dynamic fetch(String name, int line, int column, String filename,
      {bool error = true, String from = HS_Common.Global}) {
    if (defs.containsKey(name)) {
      if ((blockName == from) || (!name.startsWith(HS_Common.Underscore))) {
        return defs[name].value;
      }
      throw HSErr_Private(name, line, column, filename);
    } else {
      HS_FuncObj method = ofClass.fetchMethod(name, line, column, filename, error: false, from: from);
      if (method != null) {
        if (method.functype == FuncStmtType.normal) {
          return method.bind(this, line, column, filename);
        } else if (method.functype == FuncStmtType.getter) {
          return method.bind(this, line, column, filename).call(line, column, filename, []);
        }
      }
    }

    if (error) throw HSErr_UndefinedMember(name, this.type, line, column, filename);
  }

  @override
  void assign(String varname, dynamic value, int line, int column, String filename, {String from = HS_Common.Global}) {
    var setter = '${HS_Common.Setter}$varname';
    if (defs.containsKey(varname)) {
      if ((blockName == from) || (!varname.startsWith(HS_Common.Underscore))) {
        var vartype = defs[varname].type;
        if ((vartype == HS_Common.Dynamic) || (vartype == HS_TypeOf(value))) {
          defs[varname].value = value;
        } else {
          throw HSErr_Type(HS_TypeOf(value), vartype, line, column, filename);
        }
      } else {
        throw HSErr_Private(varname, line, column, filename);
      }
    } else {
      HS_FuncObj setter_func =
          ofClass.fetchMethod(setter, line, column, filename, error: false, from: ofClass.blockName);
      setter_func.bind(this, line, column, filename).call(line, column, filename, [value]);
    }
  }

  @override
  void assignAt(int distance, String name, dynamic value, int line, int column, String filename,
      {String from = HS_Common.Global}) {}

  dynamic invoke(String name, {List<dynamic> args}) {
    HS_FuncObj method = ofClass.fetchMethod(name, null, null, null);
    return method.bind(this, null, null, null).call(null, null, null, args ?? []);
  }
}
