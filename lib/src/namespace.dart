import 'package:hetu_script/hetu.dart';

import 'errors.dart';
import 'class.dart';
import 'common.dart';

/// Value是命名空间、类和实例的基类
abstract class HS_Value {
  String get type;
  //final int line, column;
  //final String file_name;
  HS_Value(); //this.line, this.column, this.file_name);
}

class Definition {
  String type;
  dynamic value;
  bool private;

  Definition(this.type, {this.value, this.private});
}

class Namespace extends HS_Value {
  String get type => HS_Common.Namespace;

  String _spaceName;
  String get spaceName => _spaceName;

  final String fileName;

  final Map<String, Definition> defs = {};

  Namespace _enclosing;
  Namespace get enclosing => _enclosing;

  Namespace(
      //int line, int column, String file_name,
      this.fileName,
      {Namespace enclosing,
      String spaceName})
      : super() {
    //line, column, file_name) {

    if (enclosing != null) {
      _enclosing = enclosing;
    }

    if (spaceName != null) {
      _spaceName = spaceName;
    } else if (enclosing != null) {
      _spaceName = enclosing.spaceName;
    } else {
      _spaceName = fileName;
    }
  }

  Namespace outer(int distance) {
    var namespace = this;
    for (var i = 0; i < distance; i++) {
      namespace = namespace.enclosing;
    }

    return namespace;
  }

  dynamic fetch(String name, int line, int column, String file_name,
      {bool error = true, String from = HS_Common.Global}) {
    if (defs.containsKey(name)) {
      if ((fileName == file_name) ||
          (spaceName == from) ||
          ((spaceName == HS_Common.Global) && (!name.startsWith(HS_Common.Underscore)))) {
        return defs[name].value;
      }
      throw HSErr_Private(name, line, column, file_name);
    }

    if (enclosing != null) return enclosing.fetch(name, line, column, file_name, error: error, from: from);

    if (error) throw HSErr_Undefined(name, line, column, file_name);

    return null;
  }

  dynamic fetchAt(int distance, String name, int line, int column, String file_name,
      {bool error = true, String from = HS_Common.Global}) {
    var space = outer(distance);
    return space.fetch(name, line, column, file_name, error: error, from: from);
  }

  /// 在当前命名空间声明一个指定类型的变量
  void define(String varname, String vartype, int line, int column, String file_name, {dynamic value}) {
    var val_type = HS_TypeOf(value);
    if (!defs.containsKey(varname)) {
      if ((vartype == HS_Common.Dynamic) || ((value != null) && (vartype == val_type)) || (value == null)) {
        defs[varname] = Definition(vartype, value: value);
      } else if ((value != null) && (value is Map)) {
        var klass = globalInterpreter.fetchGlobal(vartype, line, column, file_name);
        if (klass is HS_Class) {
          var instance = klass.createInstance(line, column, file_name);
          for (var key in value.keys) {
            if (instance.contains(key)) {
              instance.assign(key, value[key], line, column, file_name, from: instance.spaceName);
            }
          }
          defs[varname] = Definition(vartype, value: instance);
        } else {
          throw HSErr_Type(val_type, vartype, line, column, file_name);
        }
      }
    } else {
      throw HSErr_Defined(varname, line, column, file_name);
    }
  }

  /// 向一个已经声明的变量赋值
  void assign(String varname, dynamic value, int line, int column, String file_name, {String from = HS_Common.Global}) {
    if (defs.containsKey(varname)) {
      if ((spaceName == from) || (!varname.startsWith(HS_Common.Underscore))) {
        var vartype = defs[varname].type;
        if ((vartype == HS_Common.Dynamic) || ((value != null) && (vartype == HS_TypeOf(value))) || (value == null)) {
          defs[varname].value = value;
        } else {
          throw HSErr_Type(HS_TypeOf(value), vartype, line, column, file_name);
        }
      } else {
        throw HSErr_Private(varname, line, column, file_name);
      }
    } else if (enclosing != null) {
      enclosing.assign(varname, value, line, column, file_name, from: from);
    } else {
      throw HSErr_Undefined(varname, line, column, file_name);
    }
  }

  void assignAt(int distance, String name, dynamic value, int line, int column, String file_name,
      {String from = HS_Common.Global}) {
    var space = outer(distance);
    space.assign(name, value, line, column, file_name, from: from);
  }

  bool contains(String key) => defs.containsKey(key);

  void clear() => defs.clear();
}
