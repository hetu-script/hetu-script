import 'errors.dart';
import 'lexicon.dart';
import 'type.dart';
import 'value.dart';
import 'common.dart';

class HT_Namespace extends HT_Value with HT_Context {
  static String getFullId(String id, HT_Namespace space) {
    var fullName = id;
    var cur_space = space.closure;
    while ((cur_space != null) && (cur_space.id != HT_Lexicon.global)) {
      fullName = cur_space.id + HT_Lexicon.memberGet + fullName;
      cur_space = cur_space.closure;
    }
    return fullName;
  }

  @override
  String toString() => '${HT_Lexicon.NAMESPACE} $id';

  late String _fullName;
  String get fullName => _fullName;

  final Map<String, HT_Declaration> defs = {};
  HT_Namespace? _closure;
  HT_Namespace? get closure => _closure;
  set closure(HT_Namespace? closure) {
    _closure = closure;
    _fullName = getFullId(id, _closure!);
  }

  static int spaceIndex = 0;

  HT_Namespace({
    String? id,
    HT_Namespace? closure,
  }) : super(id ?? '${HT_Lexicon.anonymousNamespace}${spaceIndex++}') {
    _fullName = getFullId(this.id, this);
    _closure = closure;
  }

  HT_Namespace closureAt(int distance) {
    var namespace = this;
    for (var i = 0; i < distance; ++i) {
      namespace = namespace.closure!;
    }

    return namespace;
  }

  @override
  bool contains(String varName) {
    if (defs.containsKey(varName)) {
      return true;
    }
    if (closure != null) {
      return closure!.contains(varName);
    }
    return false;
  }

  /// 在当前命名空间定义一个变量的类型
  @override
  void define(String varName, CodeRunner interpreter,
      {int? line,
      int? column,
      HT_TypeId? declType,
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
        declType = HT_TypeId.ANY;
      }
    }
    if (val_type.isA(declType)) {
      defs[varName] = HT_Declaration(varName,
          declType: declType, value: value, isExtern: isExtern, isNullable: isNullable, isImmutable: isImmutable);
    } else {
      throw HTErr_Type(varName, val_type.toString(), declType.toString(), interpreter.curFileName, line, column);
    }
  }

  @override
  dynamic fetch(String varName, int? line, int? column, CodeRunner interpreter,
      {bool error = true, String from = HT_Lexicon.global, bool recursive = true}) {
    if (fullName.startsWith(HT_Lexicon.underscore) && !from.startsWith(fullName)) {
      throw HTErr_PrivateDecl(fullName, interpreter.curFileName, line, column);
    } else if (varName.startsWith(HT_Lexicon.underscore) && !from.startsWith(fullName)) {
      throw HTErr_PrivateMember(varName, interpreter.curFileName, line, column);
    }

    if (defs.containsKey(varName)) {
      return defs[varName]!.value;
    }

    if (recursive && (closure != null)) {
      return closure!.fetch(varName, line, column, interpreter, error: error, from: from);
    }

    if (error) throw HTErr_Undefined(varName, interpreter.curFileName, line, column);

    return null;
  }

  dynamic fetchAt(String varName, int distance, int? line, int? column, CodeRunner interpreter,
      {bool error = true, String from = HT_Lexicon.global, bool recursive = true}) {
    var space = closureAt(distance);
    return space.fetch(varName, line, column, interpreter, error: error, from: space.fullName, recursive: false);
  }

  /// 向一个已经定义的变量赋值
  @override
  void assign(String varName, dynamic value, int? line, int? column, CodeRunner interpreter,
      {bool error = true, String from = HT_Lexicon.global, bool recursive = true}) {
    if (fullName.startsWith(HT_Lexicon.underscore) && !from.startsWith(fullName)) {
      throw HTErr_PrivateDecl(fullName, interpreter.curFileName, line, column);
    } else if (varName.startsWith(HT_Lexicon.underscore) && !from.startsWith(fullName)) {
      throw HTErr_PrivateMember(varName, interpreter.curFileName, line, column);
    }

    if (defs.containsKey(varName)) {
      var decl_type = defs[varName]!.declType;
      var var_type = HT_TypeOf(value);
      if (var_type.isA(decl_type)) {
        var decl = defs[varName]!;
        if (!decl.isImmutable) {
          if (!decl.isExtern) {
            decl.value = value;
            return;
          } else {
            interpreter.setExternalVariable('$id.$varName', value);
            return;
          }
        }
        throw HTErr_Immutable(varName, interpreter.curFileName, line, column);
      }
      throw HTErr_Type(varName, var_type.toString(), decl_type.toString(), interpreter.curFileName, line, column);
    } else if (recursive && (closure != null)) {
      closure!.assign(varName, value, line, column, interpreter, from: from);
      return;
    }

    if (error) throw HTErr_Undefined(varName, interpreter.curFileName, line, column);
  }

  void assignAt(String varName, dynamic value, int distance, int? line, int? column, CodeRunner interpreter,
      {String from = HT_Lexicon.global, bool recursive = true}) {
    var space = closureAt(distance);
    space.assign(varName, value, line, column, interpreter, from: space.fullName, recursive: false);
  }
}
