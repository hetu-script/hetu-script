import 'package:hetu_script/hetu.dart';

import 'errors.dart';
import 'class.dart';
import 'common.dart';

/// Value是命名空间、类和实例的基类
abstract class HS_Value {
  String get type;
  //final int line, column;
  //final String filename;
  HS_Value(); //this.line, this.column, this.filename);
}

class Definition {
  String type;
  dynamic value;
  bool private;

  Definition(this.type, {this.value, this.private});
}

class Namespace extends HS_Value {
  String get type => HS_Common.Namespace;

  String _blockName;
  String get blockName => _blockName;

  final Map<String, Definition> defs = {};

  Namespace _enclosing;
  Namespace get enclosing => _enclosing;

  Namespace(
      //int line, int column, String filename,
      {Namespace enclosing,
      String blockName})
      : super() {
    //line, column, filename) {
    if (enclosing != null) {
      _enclosing = enclosing;
      _blockName = enclosing.blockName;
    } else if (blockName != null) {
      _blockName = blockName;
    } else {
      _blockName = HS_Common.Global;
    }
  }

  Namespace outer(int distance) {
    var namespace = this;
    for (var i = 0; i < distance; i++) {
      namespace = namespace.enclosing;
    }

    return namespace;
  }

  dynamic fetch(String name, int line, int column, String filename,
      {bool error = true, String from = HS_Common.Global}) {
    if (defs.containsKey(name)) {
      if ((blockName == HS_Common.Global) || (blockName == from) || (!name.startsWith(HS_Common.Underscore))) {
        return defs[name].value;
      }
      throw HSErr_Private(name, line, column, filename);
    }

    if (enclosing != null) return enclosing.fetch(name, line, column, filename, error: error, from: from);

    if (error) throw HSErr_Undefined(name, line, column, filename);

    return null;
  }

  dynamic fetchAt(int distance, String name, int line, int column, String filename,
      {bool error = true, String from = HS_Common.Global}) {
    var space = outer(distance);
    return space.fetch(name, line, column, filename, error: error, from: from);
  }

  /// 在当前命名空间声明一个指定类型的变量
  void define(String varname, String vartype, int line, int column, String filename, {dynamic value}) {
    var val_type = HS_TypeOf(value);
    if (!defs.containsKey(varname)) {
      if ((vartype == HS_Common.Dynamic) || ((value != null) && (vartype == val_type)) || (value == null)) {
        defs[varname] = Definition(vartype, value: value);
      } else if ((value != null) && (value is Map)) {
        var klass =
            globalInterpreter.fetch(vartype, line, column, filename, from: globalInterpreter.curSpace.blockName);
        if (klass is HS_Class) {
          var instance = klass.createInstance(line, column, filename);
          for (var key in value.keys) {
            if (instance.contains(key)) {
              instance.assign(key, value[key], line, column, filename, from: instance.blockName);
            }
          }
          defs[varname] = Definition(vartype, value: instance);
        } else {
          throw HSErr_Type(val_type, vartype, line, column, filename);
        }
      }
    } else {
      throw HSErr_Defined(varname, line, column, filename);
    }
  }

  /// 向一个已经声明的变量赋值
  void assign(String varname, dynamic value, int line, int column, String filename, {String from = HS_Common.Global}) {
    if (defs.containsKey(varname)) {
      if ((blockName == from) || (!varname.startsWith(HS_Common.Underscore))) {
        var vartype = defs[varname].type;
        if ((vartype == HS_Common.Dynamic) || ((value != null) && (vartype == HS_TypeOf(value))) || (value == null)) {
          defs[varname].value = value;
        } else {
          throw HSErr_Type(HS_TypeOf(value), vartype, line, column, filename);
        }
      } else {
        throw HSErr_Private(varname, line, column, filename);
      }
    } else if (enclosing != null) {
      enclosing.assign(varname, value, line, column, filename, from: from);
    } else {
      throw HSErr_Undefined(varname, line, column, filename);
    }
  }

  void assignAt(int distance, String name, dynamic value, int line, int column, String filename,
      {String from = HS_Common.Global}) {
    var space = outer(distance);
    space.assign(name, value, line, column, filename, from: from);
  }

  bool contains(String key) => defs.containsKey(key);

  void clear() => defs.clear();
}
