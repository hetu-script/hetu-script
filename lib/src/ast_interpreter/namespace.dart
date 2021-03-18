import '../errors.dart';
import '../lexicon.dart';
import 'type.dart';
import 'declaration.dart';
import 'object.dart';
import '../context.dart';
import 'ast_interpreter.dart';

class HTNamespace extends HTObject with HTContext, ASTInterpreterRef {
  static int spaceIndex = 0;

  static String getFullName(String id, HTNamespace space) {
    var fullName = id;
    var curSpace = space.closure;
    while (curSpace != null) {
      fullName = curSpace.id + HTLexicon.memberGet + fullName;
      curSpace = curSpace.closure;
    }
    return fullName;
  }

  @override
  final typeid = HTTypeId.namespace;

  late final String id;

  @override
  String toString() => '${HTLexicon.NAMESPACE} $id';

  late String _fullName;
  String get fullName => _fullName;

  final Map<String, HTDeclaration> defs = {};
  HTNamespace? _closure;
  HTNamespace? get closure => _closure;
  set closure(HTNamespace? closure) {
    _closure = closure;
    _fullName = getFullName(id, _closure!);
  }

  HTNamespace(
    HTInterpreter interpreter, {
    String? id,
    HTNamespace? closure,
  }) : super() {
    this.id = id ?? '${HTLexicon.anonymousNamespace}${spaceIndex++}';
    this.interpreter = interpreter;
    _fullName = getFullName(this.id, this);
    _closure = closure;
  }

  HTNamespace closureAt(int distance) {
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
  void define(String varName,
      {HTTypeId? declType,
      dynamic value,
      bool isExtern = false,
      bool isImmutable = false,
      bool isNullable = false,
      bool isDynamic = false}) {
    var val_type = interpreter.typeof(value);
    if (declType == null) {
      if ((!isDynamic) && (value != null)) {
        declType = val_type;
      } else {
        declType = HTTypeId.ANY;
      }
    }
    if (val_type.isA(declType)) {
      defs[varName] = HTDeclaration(varName,
          declType: declType, value: value, isExtern: isExtern, isNullable: isNullable, isImmutable: isImmutable);
    } else {
      throw HTErrorTypeCheck(varName, val_type.toString(), declType.toString());
    }
  }

  @override
  dynamic fetch(String varName, {String from = HTLexicon.global}) {
    if (fullName.startsWith(HTLexicon.underscore) && !fullName.startsWith(from)) {
      throw HTErrorPrivateDecl(fullName);
    } else if (varName.startsWith(HTLexicon.underscore) && !fullName.startsWith(from)) {
      throw HTErrorPrivateMember(varName);
    }

    if (defs.containsKey(varName)) {
      return defs[varName]!.value;
    }

    if (closure != null) {
      return closure!.fetch(varName, from: from);
    }

    throw HTErrorUndefined(varName);
  }

  dynamic fetchAt(String varName, int distance, {String from = HTLexicon.global}) {
    var space = closureAt(distance);
    return space.fetch(varName, from: space.fullName);
  }

  /// 向一个已经定义的变量赋值
  @override
  void assign(String varName, dynamic value, {String from = HTLexicon.global}) {
    if (fullName.startsWith(HTLexicon.underscore) && !fullName.startsWith(from)) {
      throw HTErrorPrivateDecl(fullName);
    } else if (varName.startsWith(HTLexicon.underscore) && !fullName.startsWith(from)) {
      throw HTErrorPrivateMember(varName);
    }

    if (defs.containsKey(varName)) {
      var decl_type = defs[varName]!.declType;
      var var_type = interpreter.typeof(value);
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
        throw HTErrorImmutable(varName);
      }
      throw HTErrorTypeCheck(varName, var_type.toString(), decl_type.toString());
    } else if (closure != null) {
      closure!.assign(varName, value, from: from);
      return;
    }

    throw HTErrorUndefined(varName);
  }

  void assignAt(String varName, dynamic value, int distance, {String from = HTLexicon.global}) {
    var space = closureAt(distance);
    space.assign(
      varName,
      value,
      from: space.fullName,
    );
  }
}
