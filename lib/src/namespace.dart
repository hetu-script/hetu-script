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

  static final global = Namespace(name: HS_Common.Global);
  static final extern = Namespace(name: HS_Common.Extern);
  static int _anonymousSpaceIndex = 0;

  /// 全局命名空间
  static final Map<String, Namespace> _spaces = {
    HS_Common.Global: global,
    HS_Common.Extern: extern,
  };

  static dynamic fetchAt(String varName, String fullName, int line, int column, String fileName) {
    var space = fetchSpace(fullName, line, column, fileName);
    return space.fetch(varName, line, column, fileName);
  }

  static Namespace fetchSpace(String fullName, int line, int column, String fileName) {
    var space = _spaces[fullName];
    if (space == null) throw HSErr_Undefined(fullName, line, column, fileName);
    return space;
  }

  String _name;
  String get name => _name;
  //String get spaceName => _spaceName;
  String _fullName;
  String get fullName => _fullName;

  final Map<String, Definition> defs = {};

  final Namespace enclosing;
  //Namespace get enclosing => _enclosing;

  Namespace(
      //int line, int column, String fileName,
      //this.fileName,
      {
    String name,
    this.enclosing,
    //Namespace enclosing,
    //String spaceName
  }) {
    //line, column, fileName) {

    // if (enclosing != null) {
    // _enclosing = enclosing;
    // }

    // if (spaceName != null) {
    //   _spaceName = spaceName;
    // } else if (enclosing != null) {
    //   _spaceName = enclosing.spaceName;
    // } else {
    //   _spaceName = fileName;
    // }

    _name = name == null ? '__anonymousSpace${_anonymousSpaceIndex++}' : name;

    _fullName = _name;
    var space = enclosing;
    while (space != null) {
      _fullName = space.name + HS_Common.Dot + _fullName;
      space = space.enclosing;
    }

    if (_spaces.containsKey(_fullName)) {
      throw HSErr_Defined(_fullName, null, null, null);
    }
  }

  Namespace outer(int distance) {
    var namespace = this;
    for (var i = 0; i < distance; i++) {
      namespace = namespace.enclosing;
    }

    return namespace;
  }

  dynamic fetch(String varName, int line, int column, String fileName,
      {bool error = true, String from = HS_Common.Global, bool recursive = true}) {
    if (defs.containsKey(varName)) {
      if ( //(fileName == fileName) ||
          (from.startsWith(this.fullName)) ||
              //(
              (this.name == HS_Common.Global) //&& (!name.startsWith(HS_Common.Underscore))
              ||
              (!name.startsWith(HS_Common.Underscore))
          //)
          ) {
        return defs[name].value;
      }
      throw HSErr_Private(name, line, column, fileName);
    }

    if (recursive && (enclosing != null))
      return enclosing.fetch(name, line, column, fileName, error: error, from: from);

    if (error) throw HSErr_Undefined(name, line, column, fileName);

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
  void define(String varname, String vartype, int line, int column, String fileName, {dynamic value}) {
    var val_type = HS_TypeOf(value);
    assert(defs.containsKey(varname));
    if ((vartype == HS_Common.Dynamic) || ((value != null) && (vartype == val_type)) || (value == null)) {
      defs[varname] = Definition(vartype, value: value);
    } else if ((value != null) && (value is Map)) {
      var klass = globalInterpreter.fetchGlobal(vartype, line, column, fileName);
      if (klass is HS_Class) {
        var instance = klass.createInstance(line, column, fileName);
        for (var key in value.keys) {
          if (instance.containsKey(key)) {
            instance.assign(key, value[key], line, column, fileName, from: instance.spaceName);
          }
        }
        defs[varname] = Definition(vartype, value: instance);
      } else {
        throw HSErr_Type(val_type, vartype, line, column, fileName);
      }
    }
  }

  /// 向一个已经定义的变量赋值
  void assign(String varname, dynamic value, int line, int column, String fileName, {String from = HS_Common.Global}) {
    if (defs.containsKey(varname)) {
      if ((spaceName == from) || (!varname.startsWith(HS_Common.Underscore))) {
        var vartype = defs[varname].type;
        if ((vartype == HS_Common.Dynamic) || ((value != null) && (vartype == HS_TypeOf(value))) || (value == null)) {
          defs[varname].value = value;
        } else {
          throw HSErr_Type(HS_TypeOf(value), vartype, line, column, fileName);
        }
      } else {
        throw HSErr_Private(varname, line, column, fileName);
      }
    } else if (enclosing != null) {
      enclosing.assign(varname, value, line, column, fileName, from: from);
    } else {
      throw HSErr_Undefined(varname, line, column, fileName);
    }
  }

  void assignAt(int distance, String name, dynamic value, int line, int column, String fileName,
      {String from = HS_Common.Global}) {
    var space = outer(distance);
    space.assign(name, value, line, column, fileName, from: from);
  }

  bool containsKey(String key) => defs.containsKey(key);

  void clear() => defs.clear();
}
