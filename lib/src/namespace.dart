import 'package:hetu_script/hetu.dart';

import 'errors.dart';
import 'class.dart';
import 'common.dart';

/// Value是命名空间、类和实例的基类
abstract class HS_Value {
  String get type;
  //final int line, column;
  //final String fileName;
  HS_Value(); //this.line, this.column, this.fileName);

}

class Definition {
  final String type;

  // 可能保存的是宿主程序的变量，因此这里是dynamic，而不是HS_Value
  dynamic value;

  Definition(this.type, {this.value});
}

class Namespace extends HS_Value {
  String get type => HS_Common.Namespace;

  String _name;
  String get name => _name;
  String _fullName;
  String get fullName => _fullName;

  final Map<String, Definition> defs = {};
  Namespace _closure;
  Namespace get closure => _closure;
  void set closure(Namespace closure) {
    _closure = closure;
    _fullName = getFullName(name, closure);
  }

  static int _anonymousSpaceIndex = 0;

  static String getFullName(String name, Namespace space) {
    var fullName = name;
    var cur_space = space;
    while (cur_space.name != HS_Common.Global) {
      fullName = cur_space.name + HS_Common.Dot + fullName;
      cur_space = cur_space.closure;
    }
    return fullName;
  }

  Namespace(
      //int line, int column, String fileName,
      //this.fileName,
      {
    String name,
    String fullName,
    Namespace closure,
  }) {
    _closure = closure == null ? global : closure;
    _name = name == null ? '__namespace${_anonymousSpaceIndex++}' : name;
    _fullName = fullName == null ? getFullName(_name, this) : fullName;
  }

  Namespace outer(int distance) {
    var namespace = this;
    for (var i = 0; i < distance; i++) {
      namespace = namespace.closure;
    }

    return namespace;
  }

  dynamic fetch(String varName, int line, int column, Interpreter interpreter,
      {bool error = true, String from = HS_Common.Global, bool recursive = true}) {
    if (defs.containsKey(varName)) {
      if (from.startsWith(this.fullName) || (this.name == HS_Common.Global) || !name.startsWith(HS_Common.Underscore)) {
        return defs[name].value;
      }
      throw HSErr_Private(name, line, column, interpreter.curFileName);
    }

    if (recursive && (closure != null)) return closure.fetch(name, line, column, interpreter, error: error, from: from);

    if (error) throw HSErr_Undefined(name, line, column, interpreter.curFileName);

    return null;
  }

  //dynamic fetchAt(int distance, String name, int line, int column, String fileName,
  //    {bool error = true, String from = HS_Common.Global}) {
  //  var space = outer(distance);
  //  return space.fetch(name, line, column, fileName, error: error, from: from);
  //}

  /// 在当前命名空间声明一个变量名称
  void declare(String varname, int line, int column, String fileName) {
    if (!defs.containsKey(varname)) {
      defs[varname] = null;
    } else {
      throw HSErr_Defined(varname, line, column, fileName);
    }
  }

  /// 在当前命名空间定义一个变量的类型
  void define(String varname, String vartype, int line, int column, Interpreter interpreter, {dynamic value}) {
    var val_type = HS_TypeOf(value);
    assert(defs.containsKey(varname));
    if ((vartype == HS_Common.Dynamic) || ((value != null) && (vartype == val_type)) || (value == null)) {
      defs[varname] = Definition(vartype, value: value);
    } else if ((value != null) && (value is Map)) {
      var klass = globalInterpreter.fetchGlobal(vartype, line, column, interpreter.curFileName);
      if (klass is HS_Class) {
        var instance = klass.createInstance(interpreter, line, column, this);
        for (var key in value.keys) {
          if (instance.contains(key)) {
            instance.assign(key, value[key], line, column, interpreter.curFileName, from: instance.name);
          }
        }
        defs[varname] = Definition(vartype, value: instance);
      } else {
        throw HSErr_Type(val_type, vartype, line, column, interpreter.curFileName);
      }
    }
  }

  /// 向一个已经定义的变量赋值
  void assign(String varname, dynamic value, int line, int column, Interpreter interpreter,
      {String from = HS_Common.Global}) {
    if (defs.containsKey(varname)) {
      if (from.startsWith(this.fullName) || (!varname.startsWith(HS_Common.Underscore))) {
        var vartype = defs[varname].type;
        if ((vartype == HS_Common.Dynamic) || ((value != null) && (vartype == HS_TypeOf(value))) || (value == null)) {
          defs[varname].value = value;
        } else {
          throw HSErr_Type(HS_TypeOf(value), vartype, line, column, interpreter.curFileName);
        }
      } else {
        throw HSErr_Private(varname, line, column, interpreter.curFileName);
      }
    } else if (closure != null) {
      closure.assign(varname, value, line, column, interpreter, from: from);
    } else {
      throw HSErr_Undefined(varname, line, column, interpreter.curFileName);
    }
  }

  // void assignAt(int distance, String name, dynamic value, int line, int column, String fileName,
  //     {String from = HS_Common.Global}) {
  //   var space = outer(distance);
  //   space.assign(name, value, line, column, interpreter, from: from);
  // }

  bool contains(String key) => defs.containsKey(key);

  void clear() => defs.clear();
}
