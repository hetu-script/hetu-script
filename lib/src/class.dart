import 'interpreter.dart';
import 'namespace.dart';
import 'common.dart';
import 'function.dart';
import 'errors.dart';
import 'statement.dart';

String HS_TypeOf(dynamic value) {
  if (value == null) {
    return HS_Common.Null;
  } else if (value is HS_Value) {
    return value.type;
  } else if (value is num) {
    return HS_Common.Num;
  } else if (value is bool) {
    return HS_Common.Bool;
  } else if (value is String) {
    return HS_Common.Str;
  } else {
    throw HSErr_Unsupport(value);
  }
}

/// [HS_Class]的实例对应河图中的"class"声明
///
/// [HS_Class]继承自命名空间[Namespace]，[HS_Class]中的变量，对应在河图中对应"class"以[static]关键字声明的成员
///
/// 类的方法单独定义在一个表中，通过[getMethod]获取
///
/// 类的静态成员定义在所继承的[Namespace]的表中，通过[define]和[fetch]定义和获取
class HS_Class extends Namespace {
  String get type => HS_Common.Class;

  String toString() => '$name';

  final String name;

  HS_Class superClass;

  List<VarStmt> _decls = [];

  Map<String, HS_Function> _methods = {};

  HS_Class(this.name,
      {String superClassName,
      List<VarStmt> variables,
      Map<String, HS_Function> methods,
      Map<String, HS_Function> staticMethods}) {
    if ((superClassName == null) && (name != HS_Common.Object)) superClassName = HS_Common.Object;
    if (superClassName != null) superClass = globalContext.fetchGlobal(superClassName);
    if (variables != null) _decls.addAll(variables);
    if (methods != null) _methods.addAll(methods);

    for (var key in staticMethods.keys) {
      var method = staticMethods[key];
      if (method is HS_Function) {
        define(key, HS_Common.Function, value: method);
      } else {
        define(key, HS_Common.Dynamic, value: method);
      }
    }
  }

  HS_Function getMethod(String name) {
    if (_methods.containsKey(name)) {
      return _methods[name];
    }

    if (superClass != null) {
      return superClass.getMethod(name);
    }

    throw HSErr_UndefinedMember(name, this.name);
  }

  dynamic fetch(String name, {bool report_exception = true}) {
    if (defs.containsKey(name)) {
      return defs[name].value;
    }

    if (report_exception) throw HSErr_Undefined(name);

    return null;
  }

  HS_Instance createInstance({String constructorName, List<dynamic> args}) {
    var instance = HS_Instance(name);

    for (var decl in _decls) {
      dynamic value;
      if (decl.initializer != null) value = globalContext.evaluateExpr(decl.initializer);

      if (decl.typename.lexeme == HS_Common.Dynamic) {
        instance.define(decl.varname.lexeme, decl.typename.lexeme, value: value);
      } else if (decl.typename.lexeme == HS_Common.Var) {
        // 如果用了var关键字，则从初始化表达式推断变量类型
        if (value != null) {
          instance.define(decl.varname.lexeme, HS_TypeOf(value), value: value);
        } else {
          instance.define(decl.varname.lexeme, HS_Common.Dynamic);
        }
      } else {
        // 接下来define函数会判断类型是否符合声明
        instance.define(decl.varname.lexeme, decl.typename.lexeme, value: value);
      }
    }

    HS_Function constructorFunction;
    constructorName ??= name;

    try {
      constructorFunction = getMethod(constructorName);
    } catch (e) {
      if (e is! HSErr_Undefined) {
        throw e;
      }
    } finally {
      if (constructorFunction is HS_Function) {
        constructorFunction.bind(instance).call(args);
      }
    }

    return instance;
  }
}

class HS_Instance extends Namespace {
  String get type => _class.name;

  @override
  String toString() => 'instance of class [${_class.name}]';

  HS_Class _class;

  HS_Instance(String class_name) {
    _class = globalContext.fetchGlobal(class_name);
  }

  dynamic get(String name) {
    if (defs.containsKey(name)) {
      return defs[name].value;
    } else {
      HS_Function method = _class.getMethod(name);
      return method.bind(this);
    }
  }

  void set(String name, dynamic value) {
    if (defs.containsKey(name)) {
      var type = defs[name].type;
      if ((type == HS_Common.Dynamic) || (type == HS_TypeOf(value))) {
        defs[name].value = value;
      } else {
        throw HSErr_Type(HS_TypeOf(value), type);
      }
    } else {
      throw HSErr_UndefinedMember(name, _class.name);
    }
  }

  dynamic invoke(String name, {List<dynamic> args}) {
    HS_Function method = _class.getMethod(name);
    return method.bind(this).call(args);
  }
}

abstract class HSVal_Literal extends HS_Instance {
  HSVal_Literal(dynamic value, String class_name) : super(class_name) {
    define('_val', HS_TypeOf(value), value: value);
  }
}

class HSVal_Num extends HSVal_Literal {
  HSVal_Num(num value) : super(value, HS_Common.Num);
}

class HSVal_Bool extends HSVal_Literal {
  HSVal_Bool(bool value) : super(value, HS_Common.Bool);
}

class HSVal_String extends HSVal_Literal {
  HSVal_String(String value) : super(value, HS_Common.Str);
}
