import 'package:hetu_script/hetu.dart';

import 'errors.dart';
import 'class.dart';
import 'common.dart';
import 'value.dart';

class HS_Namespace extends HS_Value {
  String toString() => '${HS_Common.NAMESPACE} $name';

  String _fullName;
  String get fullName => _fullName;

  final Map<String, Declaration> defs = {};
  HS_Namespace _closure;
  HS_Namespace get closure => _closure;
  void set closure(HS_Namespace closure) {
    _closure = closure;
    _fullName = getFullName(this.name, _closure);
  }

  static int spaceIndex = 0;

  static String getFullName(String name, HS_Namespace space) {
    var fullName = name;
    var cur_space = space.closure;
    while ((cur_space != null) && (cur_space.name != HS_Common.global)) {
      fullName = cur_space.name + HS_Common.dot + fullName;
      cur_space = cur_space.closure;
    }
    return fullName;
  }

  HS_Namespace({
    String name,
    HS_Namespace closure,
  }) : super(name: name ?? '__namespace${spaceIndex++}') {
    _fullName = getFullName(this.name, this);
    _closure = closure;
  }

  HS_Namespace closureAt(int distance) {
    var namespace = this;
    for (var i = 0; i < distance; ++i) {
      namespace = namespace.closure;
    }

    return namespace;
  }

  bool contains(String varName) {
    if (defs.containsKey(varName)) return true;
    if (closure != null) return closure.contains(varName);
    return false;
  }

  // String lookUp(String varName) {
  //   String fullName = varName;
  //   var space = this;
  //   while (!space.contains(varName)) {
  //     space = space.closure;
  //     if (space == null) {
  //       return null;
  //     }
  //     fullName = space.name + HS_Common.Dot + fullName;
  //   }
  //   return fullName;
  // }

  /// 在当前命名空间声明一个变量名称
  // void declare(String varName, int line, int column, String fileName) {
  //   if (!defs.containsKey(varName)) {
  //     defs[varName] = null;
  //   } else {
  //     throw HSErr_Defined(varName, line, column, fileName);
  //   }
  // }

  /// 在当前命名空间定义一个变量的类型
  void define(String id, HS_Type typeid, int line, int column, Interpreter interpreter,
      {dynamic value, bool mutable = true}) {
    var val_typeid = HS_TypeOf(value);
    if (val_typeid.isA(typeid)) {
      if (typeid.arguments.isNotEmpty) {
        for (int i = 0; i < val_typeid.typeArgs.length; ++i) {
          if (i < typeid.typeArgs.length) {
            var decl_type_param = typeid.typeArgs[i];
            var val_type_param = val_typeid.typeArgs[i];
            if ((decl_type_param != HS_Common.ANY) && (decl_type_param != val_type_param)) {
              throw HSErr_TypeParam(
                  val_type_param.toString(), decl_type_param.toString(), line, column, interpreter.curFileName);
            }
          } else {
            typeid.typeArgs.add(HS_Type.any);
          }
        }
      }
      defs[id] = Declaration(typeid, value: value, mutable: mutable);
    } else if ((value != null) && (value is Map)) {
      var klass = interpreter.global.fetch(id, line, column, interpreter);
      if (klass is HS_Class) {
        var instance = klass.createInstance(interpreter, line, column, this);
        for (var key in value.keys) {
          instance.assign(key, value[key], line, column, interpreter);
        }
        defs[id] = Declaration(typeid, value: instance);
      } else {
        throw HSErr_Type(id, typeid.toString(), val_typeid.toString(), line, column, interpreter.curFileName);
      }
    } else {
      throw HSErr_Type(id, typeid.toString(), val_typeid.toString(), line, column, interpreter.curFileName);
    }
  }

  dynamic fetch(String varName, int line, int column, Interpreter interpreter,
      {bool nonExistError = true, String from = HS_Common.global, bool recursive = true}) {
    if (defs.containsKey(varName)) {
      if (from.startsWith(this.fullName) || (name == HS_Common.global) || !varName.startsWith(HS_Common.underscore)) {
        return defs[varName].value;
      }
      throw HSErr_Private(varName, line, column, interpreter.curFileName);
    }

    if (recursive && (closure != null))
      return closure.fetch(varName, line, column, interpreter, nonExistError: nonExistError, from: from);

    if (nonExistError) throw HSErr_Undefined(varName, line, column, interpreter.curFileName);

    return null;
  }

  dynamic fetchAt(String varName, int distance, int line, int column, Interpreter interpreter,
      {bool nonExistError = true, String from = HS_Common.global, bool recursive = true}) {
    var space = closureAt(distance);
    return space.fetch(varName, line, column, interpreter,
        nonExistError: nonExistError, from: space.fullName, recursive: false);
  }

  /// 向一个已经定义的变量赋值
  void assign(String varName, dynamic value, int line, int column, Interpreter interpreter,
      {bool nonExistError = true, String from = HS_Common.global, bool recursive = true}) {
    if (defs.containsKey(varName)) {
      var declType = defs[varName].typeid;
      var varType = HS_TypeOf(value);
      if (from.startsWith(this.fullName) || (!varName.startsWith(HS_Common.underscore))) {
        if ((declType == HS_Common.ANY) || ((value != null) && (declType == varType)) || (value == null)) {
          if (defs[varName].mutable) {
            defs[varName].value = value;
            return;
          }
          throw HSErr_Mutable(varName, line, column, interpreter.curFileName);
        }
        throw HSErr_Type(varName, varType.toString(), declType.toString(), line, column, interpreter.curFileName);
      }
      throw HSErr_Private(varName, line, column, interpreter.curFileName);
    } else if (recursive && (closure != null)) {
      closure.assign(varName, value, line, column, interpreter, from: from);
      return;
    }

    if (nonExistError) throw HSErr_Undefined(varName, line, column, interpreter.curFileName);
  }

  void assignAt(String varName, dynamic value, int distance, int line, int column, Interpreter interpreter,
      {String from = HS_Common.global, bool recursive = true}) {
    var space = closureAt(distance);
    space.assign(varName, value, line, column, interpreter, from: space.fullName, recursive: false);
  }
}
