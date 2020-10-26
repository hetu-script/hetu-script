import 'errors.dart';
import 'environment.dart';
import 'value.dart';
import 'interpreter.dart';

class HT_Namespace extends HT_Value {
  String toString() => '${env.lexicon.NAMESPACE} $name';

  String _fullName;
  String get fullName => _fullName;

  final Map<String, Declaration> defs = {};
  HT_Namespace _closure;
  HT_Namespace get closure => _closure;
  void set closure(HT_Namespace closure) {
    _closure = closure;
    _fullName = getFullName(this.name, _closure);
  }

  static int spaceIndex = 0;

  static String getFullName(String name, HT_Namespace space) {
    var fullName = name;
    var cur_space = space.closure;
    while ((cur_space != null) && (cur_space.name != env.lexicon.globals)) {
      fullName = cur_space.name + env.lexicon.memberGet + fullName;
      cur_space = cur_space.closure;
    }
    return fullName;
  }

  HT_Namespace({
    String name,
    HT_Namespace closure,
  }) : super(name: name ?? '__namespace${spaceIndex++}') {
    _fullName = getFullName(this.name, this);
    _closure = closure;
  }

  HT_Namespace closureAt(int distance) {
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
  //     fullName = space.name + env.lexicon.Dot + fullName;
  //   }
  //   return fullName;
  // }

  /// 在当前命名空间声明一个变量名称
  // void declare(String varName, int line, int column, String fileName) {
  //   if (!defs.containsKey(varName)) {
  //     defs[varName] = null;
  //   } else {
  //     throw HTErr_Defined(varName, line, column, fileName);
  //   }
  // }

  /// 在当前命名空间定义一个变量的类型
  void define(String id, Interpreter interpreter,
      {int line, int column, HT_Type declType, dynamic value, bool isMutable = true, bool typeInference = true}) {
    var val_type = HT_TypeOf(value);
    if (declType == null) {
      if ((typeInference) && (value != null)) {
        declType = val_type;
      } else {
        declType = HT_Type.ANY;
      }
    }
    if (val_type.isA(declType)) {
      defs[id] = Declaration(declType, value: value, isMutable: isMutable);
    } else {
      throw HTErr_Type(id, val_type.toString(), declType.toString(), line, column, interpreter.curFileName);
    }
  }

  dynamic fetch(String varName, int line, int column, Interpreter interpreter,
      {bool error = true, String from, bool recursive = true}) {
    from ??= env.lexicon.globals;
    if (defs.containsKey(varName)) {
      if (from.startsWith(this.fullName) ||
          (name == env.lexicon.globals) ||
          !varName.startsWith(env.lexicon.underscore)) {
        return defs[varName].value;
      }
      throw HTErr_Private(varName, line, column, interpreter.curFileName);
    }

    if (recursive && (closure != null))
      return closure.fetch(varName, line, column, interpreter, error: error, from: from);

    if (error) throw HTErr_Undefined(varName, line, column, interpreter.curFileName);

    return null;
  }

  dynamic fetchAt(String varName, int distance, int line, int column, Interpreter interpreter,
      {bool error = true, String from, bool recursive = true}) {
    from ??= env.lexicon.globals;
    var space = closureAt(distance);
    return space.fetch(varName, line, column, interpreter, error: error, from: space.fullName, recursive: false);
  }

  /// 向一个已经定义的变量赋值
  void assign(String varName, dynamic value, int line, int column, Interpreter interpreter,
      {bool error = true, String from, bool recursive = true}) {
    from ??= env.lexicon.globals;
    if (defs.containsKey(varName)) {
      var decl_type = defs[varName].typeid;
      var var_type = HT_TypeOf(value);
      if (from.startsWith(this.fullName) || (!varName.startsWith(env.lexicon.underscore))) {
        if (var_type.isA(decl_type)) {
          if (defs[varName].isMutable) {
            defs[varName].value = value;
            return;
          }
          throw HTErr_Mutable(varName, line, column, interpreter.curFileName);
        }
        throw HTErr_Type(varName, var_type.toString(), decl_type.toString(), line, column, interpreter.curFileName);
      }
      throw HTErr_Private(varName, line, column, interpreter.curFileName);
    } else if (recursive && (closure != null)) {
      closure.assign(varName, value, line, column, interpreter, from: from);
      return;
    }

    if (error) throw HTErr_Undefined(varName, line, column, interpreter.curFileName);
  }

  void assignAt(String varName, dynamic value, int distance, int line, int column, Interpreter interpreter,
      {String from, bool recursive = true}) {
    from ??= env.lexicon.globals;
    var space = closureAt(distance);
    space.assign(varName, value, line, column, interpreter, from: space.fullName, recursive: false);
  }
}
