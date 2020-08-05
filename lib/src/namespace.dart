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

class Field {
  final String type;
  // 可能保存的是宿主程序的变量，因此这里是dynamic，而不是HS_Value
  dynamic value;
  bool mutable;

  Field(this.type, {this.value, this.mutable = true});
}

class Namespace extends HS_Value {
  String get type => HS_Common.Namespace;

  String _name;
  String get name => _name;
  String _fullName;
  String get fullName => _fullName;

  final Map<String, Field> defs = {};
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
    _name = name == null ? '__namespace${_anonymousSpaceIndex++}' : name;
    _closure = closure;
    _fullName = fullName == null ? getFullName(_name, this) : fullName;
  }

  // Namespace outer(int distance) {
  //   var namespace = this;
  //   for (var i = 0; i < distance; i++) {
  //     namespace = namespace.closure;
  //   }

  //   return namespace;
  // }

  bool contains(String varName) {
    if (defs.containsKey(varName)) return true;
    if (closure != null) return closure.contains(varName);
    return false;
  }

  String lookUp(String varName) {
    String fullName = name;
    var space = this;
    while (!space.contains(varName)) {
      space = space.closure;
      if (space == null) {
        return null;
      }
      fullName = space.name + HS_Common.Dot + fullName;
    }
    return fullName;
  }

  //dynamic fetchAt(int distance, String name, int line, int column, String fileName,
  //    {bool error = true, String from = HS_Common.Global}) {
  //  var space = outer(distance);
  //  return space.fetch(name, line, column, fileName, error: error, from: from);
  //}

  /// 在当前命名空间声明一个变量名称
  void declare(String varName, int line, int column, String fileName) {
    if (!defs.containsKey(varName)) {
      defs[varName] = null;
    } else {
      throw HSErr_Defined(varName, line, column, fileName);
    }
  }

  /// 在当前命名空间定义一个变量的类型
  void define(String varName, String varType, int line, int column, Interpreter interpreter, {dynamic value}) {
    var val_type = HS_TypeOf(value);
    assert(defs.containsKey(varName));
    if ((varType == HS_Common.Dynamic) || ((value != null) && (varType == val_type)) || (value == null)) {
      defs[varName] = Field(varType, value: value);
    } else if ((value != null) && (value is Map)) {
      var klass = interpreter.global.fetch(varType, line, column, interpreter);
      if (klass is HS_Class) {
        var instance = klass.createInstance(interpreter, line, column, this);
        for (var key in value.keys) {
          instance.setValue(key, value[key], line, column, interpreter, error: false);
        }
        defs[varName] = Field(varType, value: instance);
      } else {
        throw HSErr_Type(val_type, varType, line, column, interpreter.curFileName);
      }
    }
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

  /// 向一个已经定义的变量赋值
  void assign(String varName, dynamic value, int line, int column, Interpreter interpreter,
      {String from = HS_Common.Global, bool recursive = true}) {
    if (defs.containsKey(varName)) {
      if (from.startsWith(this.fullName) || (!varName.startsWith(HS_Common.Underscore))) {
        var varType = defs[varName].type;
        if ((varType == HS_Common.Dynamic) || ((value != null) && (varType == HS_TypeOf(value))) || (value == null)) {
          defs[varName].value = value;
        } else {
          throw HSErr_Type(HS_TypeOf(value), varType, line, column, interpreter.curFileName);
        }
      } else {
        throw HSErr_Private(varName, line, column, interpreter.curFileName);
      }
    } else if (recursive && (closure != null)) {
      closure.assign(varName, value, line, column, interpreter, from: from);
    } else {
      throw HSErr_Undefined(varName, line, column, interpreter.curFileName);
    }
  }

  // void assignAt(int distance, String name, dynamic value, int line, int column, String fileName,
  //     {String from = HS_Common.Global}) {
  //   var space = outer(distance);
  //   space.assign(name, value, line, column, interpreter, from: from);
  // }
}
