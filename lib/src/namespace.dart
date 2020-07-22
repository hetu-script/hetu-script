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

  Definition(this.type, {this.value});
}

class Namespace extends HS_Value {
  String get type => HS_Common.Namespace;

  final Map<String, Definition> defs = {};

  Namespace _enclosing;
  Namespace get enclosing => _enclosing;

  Namespace([Namespace enclosing]) {
    _enclosing = enclosing;
  }

  Namespace outer(int distance) {
    var namespace = this;
    for (var i = 0; i < distance; i++) {
      namespace = namespace.enclosing;
    }

    return namespace;
  }

  dynamic fetch(String name, {bool report_exception = true}) {
    if (defs.containsKey(name)) {
      return defs[name].value;
    }

    if (enclosing != null) return enclosing.fetch(name);

    if (report_exception) throw HSErr_Undefined(name);

    return null;
  }

  dynamic fetchAt(int distance, String name, {bool report_exception = true}) => outer(distance).fetch(name);

  /// 在当前命名空间声明一个指定类型的变量
  void define(String name, String type, {dynamic value}) {
    if (!defs.containsKey(name)) {
      if ((type == HS_Common.Dynamic) || ((value != null) && (type == HS_TypeOf(value))) || (value == null)) {
        defs[name] = Definition(type, value: value);
      } else {
        throw HSErr_Type(HS_TypeOf(value), type);
      }
    } else {
      throw HSErr_Defined(name);
    }
  }

  /// 向一个已经声明的变量赋值
  void assign(String name, dynamic value) {
    if (defs.containsKey(name)) {
      var type = defs[name].type;
      if ((type == HS_Common.Dynamic) || (type == HS_TypeOf(value))) {
        defs[name].value = value;
      } else {
        throw HSErr_Type(HS_TypeOf(value), type);
      }
    } else if (enclosing != null) {
      enclosing.assign(name, value);
    } else {
      throw HSErr_Undefined(name);
    }
  }

  void assignAt(int distance, String name, dynamic value) => outer(distance).assign(name, value);

  bool contains(String key) => defs.containsKey(key);

  void clear() => defs.clear();
}
