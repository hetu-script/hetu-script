import 'errors.dart';
import 'lexicon.dart';
import 'value.dart';
import 'interpreter.dart';
import 'common.dart';

class HT_Namespace extends HT_Value with HT_Context {
  @override
  String toString() => '${HT_Lexicon.NAMESPACE} $id';

  String _fullName;
  String get fullName => _fullName;

  final Map<String, HT_Declaration> defs = {};
  HT_Namespace _closure;
  HT_Namespace get closure => _closure;
  set closure(HT_Namespace closure) {
    _closure = closure;
    _fullName = getFullId(id, _closure);
  }

  static int spaceIndex = 0;

  HT_Namespace({
    String id,
    HT_Namespace closure,
  }) : super(id: id ?? '__namespace${spaceIndex++}') {
    _fullName = getFullId(id, this);
    _closure = closure;
  }

  static String getFullId(String id, HT_Namespace space) {
    var fullName = id;
    var cur_space = space.closure;
    while ((cur_space != null) && (cur_space.id != HT_Lexicon.globals)) {
      fullName = cur_space.id + HT_Lexicon.memberGet + fullName;
      cur_space = cur_space.closure;
    }
    return fullName;
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
  void define(String id, HT_Interpreter interpreter,
      {int line,
      int column,
      HT_Type declType,
      dynamic value,
      bool isExtern = false,
      bool isImmutable = false,
      bool isNullable = false,
      bool isDynamic = false}) {
    var val_type = HT_TypeOf(value);
    if (declType == null) {
      if ((!isDynamic) && (value != null)) {
        declType = val_type;
      } else {
        declType = HT_Type.ANY;
      }
    }
    if (val_type.isA(declType)) {
      defs[id] = HT_Declaration(id,
          declType: declType, value: value, isExtern: isExtern, isNullable: isNullable, isImmutable: isImmutable);
    } else {
      throw HTErr_Type(id, val_type.toString(), declType.toString(), interpreter.curFileName, line, column);
    }
  }

  dynamic fetch(String varName, int line, int column, HT_Interpreter interpreter,
      {bool error = true, String from = HT_Lexicon.globals, bool recursive = true}) {
    if (defs.containsKey(varName)) {
      if (from.startsWith(fullName) || (id == HT_Lexicon.globals) || !varName.startsWith(HT_Lexicon.underscore)) {
        return defs[varName].value;
      }
      throw HTErr_PrivateMember(varName, interpreter.curFileName, line, column);
    }

    if (recursive && (closure != null)) {
      return closure.fetch(varName, line, column, interpreter, error: error, from: from);
    }

    if (error) throw HTErr_Undefined(varName, interpreter.curFileName, line, column);

    return null;
  }

  dynamic fetchAt(String varName, int distance, int line, int column, HT_Interpreter interpreter,
      {bool error = true, String from = HT_Lexicon.globals, bool recursive = true}) {
    var space = closureAt(distance);
    return space.fetch(varName, line, column, interpreter, error: error, from: space.fullName, recursive: false);
  }

  /// 向一个已经定义的变量赋值
  void assign(String varName, dynamic value, int line, int column, HT_Interpreter interpreter,
      {bool error = true, String from = HT_Lexicon.globals, bool recursive = true}) {
    if (defs.containsKey(varName)) {
      var decl_type = defs[varName].declType;
      var var_type = HT_TypeOf(value);
      if (from.startsWith(fullName) || (!varName.startsWith(HT_Lexicon.underscore))) {
        if (var_type.isA(decl_type)) {
          if (!defs[varName].isImmutable) {
            defs[varName].value = value;
            return;
          }
          throw HTErr_Immutable(varName, interpreter.curFileName, line, column);
        }
        throw HTErr_Type(varName, var_type.toString(), decl_type.toString(), interpreter.curFileName, line, column);
      }
      throw HTErr_PrivateMember(varName, interpreter.curFileName, line, column);
    } else if (recursive && (closure != null)) {
      closure.assign(varName, value, line, column, interpreter, from: from);
      return;
    }

    if (error) throw HTErr_Undefined(varName, interpreter.curFileName, line, column);
  }

  void assignAt(String varName, dynamic value, int distance, int line, int column, HT_Interpreter interpreter,
      {String from = HT_Lexicon.globals, bool recursive = true}) {
    var space = closureAt(distance);
    space.assign(varName, value, line, column, interpreter, from: space.fullName, recursive: false);
  }
}
