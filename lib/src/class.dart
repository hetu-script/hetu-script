import 'interpreter.dart';
import 'namespace.dart';
import 'common.dart';
import 'function.dart';
import 'errors.dart';
import 'statement.dart';

/// [Class]的实例对应河图中的"class"声明
///
/// [Class]继承自命名空间[Namespace]，[Class]中的变量，对应在河图中对应"class"以[static]关键字声明的成员
class Class extends Namespace {
  String get type => Common.Class;

  String toString() => '$name';

  final String name;

  Class superClass;

  List<VarStmt> _decls = [];

  Map<String, Subroutine> _methods = {};

  Class(this.name, {this.superClass, List<VarStmt> decls, Map<String, Subroutine> methods}) {
    if ((name != Common.Object) && (superClass == null)) superClass = htObject;
    if (decls != null) _decls.addAll(decls);
    if (methods != null) _methods.addAll(methods);
  }

  Subroutine get(String name) {
    if (_methods.containsKey(name)) {
      return _methods[name];
    }

    if (superClass != null) {
      return superClass.get(name);
    }

    throw HetuErrorUndefinedMember(name, this.name);
  }

  Instance createInstance({String constructorName, List<Instance> args}) {
    var instance = Instance(this);

    for (var decl in _decls) {
      Instance value;
      if (decl.initializer != null) value = globalContext.evaluate(decl.initializer);

      if (decl.typename.lexeme == Common.Dynamic) {
        instance.define(decl.varname.lexeme, decl.typename.lexeme, value: value);
      } else if (decl.typename.lexeme == Common.Var) {
        // 如果用了var关键字，则从初始化表达式推断变量类型
        if (value != null) {
          instance.define(decl.varname.lexeme, value.type, value: value);
        } else {
          instance.define(decl.varname.lexeme, Common.Dynamic);
        }
      } else {
        // 接下来define函数会判断类型是否符合声明
        instance.define(decl.varname.lexeme, decl.typename.lexeme, value: value);
      }
    }

    Subroutine constructorFunction;
    constructorName ??= name;

    try {
      constructorFunction = get(constructorName);
    } catch (e) {
      if (e is! HetuErrorUndefined) {
        throw e;
      }
    } finally {
      if (constructorFunction is Subroutine) {
        constructorFunction.bind(instance).call(args);
      }
    }

    return instance;
  }

  static final NULL = Class(
    Common.Null,
    superClass: htObject,
  );
}

class Instance extends Namespace {
  String get type => ofClass.name;

  @override
  String toString() => 'instance of class [${ofClass.name}]';

  final Class ofClass;

  Instance(this.ofClass);

  Instance get(String name) {
    if (defs.containsKey(name)) {
      return defs[name].value;
    } else {
      Subroutine method = ofClass.get(name);
      if (method != null) return method.bind(this);
      throw HetuErrorUndefined(name);
    }
  }

  void set(String name, Instance value) {
    if (defs.containsKey(name)) {
      var variableType = defs[name].type;
      if ((variableType == Common.Dynamic) || (variableType == value.type)) {
        // 直接改写wrapper里面的值就行，不用重新生成wrapper
        defs[name].value = value;
      } else {
        throw HetuErrorType(value.type, variableType);
      }
    } else {
      throw HetuErrorUndefinedMember(name, ofClass.name);
    }
  }
}

/// 一个叫做"Object"的class，是河图中所有对象的基类，在这里用Dart手写出其实例
var htObject = Class(
  Common.Object,
  superClass: null,
);

var htFunction = Class(
  Common.Function,
  superClass: htObject,
);

var htNull = Class(
  Common.Null,
  superClass: htObject,
);

var htNum = Class(
  Common.Num,
  superClass: htObject,
);

var htBool = Class(
  Common.Bool,
  superClass: htObject,
);

var htString = Class(
  Common.Str,
  superClass: htObject,
);

abstract class Literal extends Instance {
  dynamic value;

  @override
  String toString() => value.toString();

  Literal(this.value, Class ofClass) : super(ofClass);
}

class LNull extends Literal {
  String get type => Common.Null;

  LNull() : super(null, htNull);
}

/// 只在get成员时使用，如果是计算的话，则直接使用Dart的字面量
class LNum extends Literal {
  String get type => Common.Num;

  LNum(num value) : super(value.toString, htNum);
}

/// 只在get成员时使用，如果是计算的话，则直接使用Dart的字面量
class LBool extends Literal {
  String get type => Common.Bool;

  LBool(bool value) : super(value.toString, htBool);
}

/// 只在get成员时使用，如果是计算的话，则直接使用Dart的字面量
class LString extends Literal {
  String get type => Common.Str;

  LString(String value) : super(value, htString);
}
