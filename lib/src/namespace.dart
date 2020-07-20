import 'errors.dart';
import 'class.dart';
import 'constants.dart';

/// Identifier是命名空间、类和实例的基类
abstract class Identifier {
  String get type;
}

class Definition {
  String type;
  Identifier value;

  Definition(this.type, {this.value});
}

class Namespace extends Identifier {
  String get type => Constants.Namespace;

  final Map<String, Definition> defs = {};

  Namespace _enclosing;
  Namespace get enclosing => _enclosing;

  Namespace([Namespace enclosing]) {
    _enclosing = enclosing;
  }

  Namespace upper(int distance) {
    var namespace = this;
    for (var i = 0; i < distance; i++) {
      namespace = namespace.enclosing;
    }

    return namespace;
  }

  Instance getVar(String name) {
    if (defs.containsKey(name)) {
      return defs[name].value;
    }

    if (enclosing != null) return enclosing.getVar(name);

    throw HetuErrorUndefined(name);
  }

  Instance getVarAt(int distance, String name) => upper(distance).getVar(name);

  /// 在当前命名空间声明一个指定类型的变量
  void define(String name, String type, {Identifier value}) {
    if (!defs.containsKey(name)) {
      if ((type == Constants.Dynamic) || ((value != null) && (type == value.type)) || (value == null)) {
        defs[name] = Definition(type, value: value);
      } else {
        throw HetuErrorType(value.type, type);
      }
    } else {
      throw HetuErrorDefined(name);
    }
  }

  /// 向一个已经声明的变量赋值
  void assign(String name, Identifier value) {
    if (defs.containsKey(name)) {
      var variableType = defs[name].type;
      if ((variableType == Constants.Dynamic) || (variableType == value.type)) {
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

  void assignAt(int distance, String name, dynamic value) => upper(distance).assign(name, value);

  bool contains(String key) => defs.containsKey(key);

  void clear() => defs.clear();
}
