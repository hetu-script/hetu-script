import 'errors.dart';
import 'class.dart';
import 'common.dart';

/// Value是命名空间、类和实例的基类
abstract class Value {
  String get type;
}

class Definition {
  String type;
  Value value;

  Definition(this.type, {this.value});
}

class ConstantMarker {}

class Namespace extends Value {
  String get type => Common.Namespace;

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

  Value fetch(String name) {
    if (defs.containsKey(name)) {
      return defs[name].value;
    }

    if (enclosing != null) return enclosing.fetch(name);

    throw HetuErrorUndefined(name);
  }

  Value fetchAt(int distance, String name) => outer(distance).fetch(name);

  /// 在当前命名空间声明一个指定类型的变量
  void define(String name, String type, {Value value}) {
    if (!defs.containsKey(name)) {
      if ((type == Common.Dynamic) || ((value != null) && (type == value.type)) || (value == null)) {
        defs[name] = Definition(type, value: value);
      } else {
        throw HetuErrorType(value.type, type);
      }
    } else {
      throw HetuErrorDefined(name);
    }
  }

  /// 向一个已经声明的变量赋值
  void assign(String name, Value value) {
    if (defs.containsKey(name)) {
      var variableType = defs[name].type;
      if ((variableType == Common.Dynamic) || (variableType == value.type)) {
        defs[name].value = value;
      } else {
        throw HetuErrorType(value.type, variableType);
      }
    } else if (enclosing != null) {
      enclosing.assign(name, value);
    } else {
      throw HetuErrorUndefined(name);
    }
  }

  void assignAt(int distance, String name, dynamic value) => outer(distance).assign(name, value);

  bool contains(String key) => defs.containsKey(key);

  void clear() => defs.clear();
}
