import 'errors.dart';
import 'lexicon.dart';
import 'type.dart';
import 'interpreter.dart';
import 'declaration.dart';
import 'object.dart';

class HTNamespace extends HTObject with InterpreterRef {
  static int spaceIndex = 0;

  static String getFullName(String id, HTNamespace? space) {
    var fullName = id;
    var curSpace = space?.closure;
    while (curSpace != null) {
      fullName = curSpace.id + HTLexicon.memberGet + fullName;
      curSpace = curSpace.closure;
    }
    return fullName;
  }

  @override
  String toString() => '${HTLexicon.NAMESPACE} $id';

  @override
  final typeid = HTTypeId.namespace;

  late final String id;

  late final String _fullName;
  String get fullName => _fullName;

  /// 常量表
  final _constInt = <int>[];
  List<int> get constInt => _constInt.toList(growable: false);
  int addConstInt(int value) {
    for (var i = 0; i < _constInt.length; ++i) {
      if (_constInt[i] == value) return i;
    }

    _constInt.add(value);
    return _constInt.length - 1;
  }

  int getConstInt(int index) => _constInt[index];

  final _constFloat = <double>[];
  List<double> get constFloat => _constFloat.toList(growable: false);
  int addConstFloat(double value) {
    for (var i = 0; i < _constFloat.length; ++i) {
      if (_constFloat[i] == value) return i;
    }

    _constFloat.add(value);
    return _constFloat.length - 1;
  }

  double getConstFloat(int index) => _constFloat[index];

  final _constString = <String>[];
  List<String> get constUtf8String => _constString.toList(growable: false);
  int addConstString(String value) {
    for (var i = 0; i < _constString.length; ++i) {
      if (_constString[i] == value) return i;
    }

    _constString.add(value);
    return _constString.length - 1;
  }

  String getConstString(int index) => _constString[index];

  // 变量表
  final Map<String, HTDeclaration> declarations = {};

  HTNamespace? _closure;
  HTNamespace? get closure => _closure;
  set closure(HTNamespace? closure) {
    _closure = closure;
    _fullName = getFullName(id, _closure!);
  }

  HTNamespace(
    Interpreter interpreter, {
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
    if (declarations.containsKey(varName)) {
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
      bool typeInference = false}) {
    var val_type = interpreter.typeof(value);
    if (declType == null) {
      if ((typeInference) && (value != null)) {
        declType = val_type;
      } else {
        declType = HTTypeId.ANY;
      }
    }
    if (val_type.isA(declType)) {
      declarations[varName] = HTDeclaration(varName,
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

    if (declarations.containsKey(varName)) {
      return declarations[varName]!.value;
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

    if (declarations.containsKey(varName)) {
      var decl_type = declarations[varName]!.declType;
      var var_type = interpreter.typeof(value);
      if (var_type.isA(decl_type)) {
        var decl = declarations[varName]!;
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
