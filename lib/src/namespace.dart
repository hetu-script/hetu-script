import 'package:hetu_script/hetu.dart';

import 'errors.dart';
import 'class.dart';
import 'common.dart';

/// Value是命名空间、类和实例的基类
abstract class HS_Value {
  String get type;
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

  Namespace({Namespace enclosing, String blockName}) {
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

  dynamic fetch(String name, {bool error = true, String from = HS_Common.Global}) {
    if (defs.containsKey(name)) {
      if ((blockName == HS_Common.Global) || (blockName == from) || (!name.startsWith(HS_Common.Underscore))) {
        return defs[name].value;
      }
      throw HSErr_Private(name);
    }

    if (enclosing != null) return enclosing.fetch(name, error: error, from: from);

    if (error) throw HSErr_Undefined(name);

    return null;
  }

  dynamic fetchAt(int distance, String name, {bool error = true, String from = HS_Common.Global}) {
    var space = outer(distance);
    return space.fetch(name, error: error, from: from);
  }

  /// 在当前命名空间声明一个指定类型的变量
  void define(String varname, String vartype, {dynamic value}) {
    var val_type = HS_TypeOf(value);
    if (!defs.containsKey(varname)) {
      if ((vartype == HS_Common.Dynamic) || ((value != null) && (vartype == val_type)) || (value == null)) {
        defs[varname] = Definition(vartype, value: value);
      } else if ((value != null) && (value is Map)) {
        var klass = globalInterpreter.fetchGlobal(vartype, from: globalInterpreter.curSpace.blockName);
        if (klass is HS_Class) {
          var instance = klass.createInstance();
          for (var key in value.keys) {
            if (instance.contains(key)) {
              instance.assign(key, value[key], from: instance.blockName);
            }
          }
          defs[varname] = Definition(vartype, value: instance);
        } else {
          throw HSErr_Type(val_type, vartype);
        }
      }
    } else {
      throw HSErr_Defined(varname);
    }
  }

  /// 向一个已经声明的变量赋值
  void assign(String varname, dynamic value, {String from = HS_Common.Global}) {
    if (defs.containsKey(varname)) {
      if ((blockName == from) || (!varname.startsWith(HS_Common.Underscore))) {
        var vartype = defs[varname].type;
        if ((vartype == HS_Common.Dynamic) || ((value != null) && (vartype == HS_TypeOf(value))) || (value == null)) {
          defs[varname].value = value;
        } else {
          throw HSErr_Type(HS_TypeOf(value), vartype);
        }
      } else {
        throw HSErr_Private(varname);
      }
    } else if (enclosing != null) {
      enclosing.assign(varname, value, from: from);
    } else {
      throw HSErr_Undefined(varname);
    }
  }

  void assignAt(int distance, String name, dynamic value, {String from = HS_Common.Global}) {
    var space = outer(distance);
    space.assign(name, value, from: from);
  }

  bool contains(String key) => defs.containsKey(key);

  void clear() => defs.clear();
}
