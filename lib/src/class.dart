import 'interpreter.dart';
import 'namespace.dart';
import 'constants.dart';
import 'function.dart';
import 'errors.dart';
import 'statement.dart';

/// [Class]的实例对应河图中的"class"声明
///
/// [Class]继承自命名空间[Namespace]，[Class]中的变量，对应在河图中对应"class"以[static]关键字声明的成员
class Class extends Namespace {
  String get type => Constants.Class;

  String toString() => '$name';

  final String name;

  final Class superClass;

  List<VarStmt> _decls = [];

  Map<String, Subroutine> _methods = {};

  Class(this.name, {this.superClass, List<VarStmt> decls, Map<String, Subroutine> methods}) {
    if (decls != null) _decls.addAll(decls);
    if (methods != null) _methods.addAll(methods);
  }

  Subroutine getMethod(String name) {
    if (_methods.containsKey(name)) {
      return _methods[name];
    }

    if (superClass != null) {
      return superClass.getMethod(name);
    }

    throw HetuErrorUndefinedMember(name, this.name);
  }

  Instance generateInstance({String constructorName, List<Instance> args}) {
    var instance = Instance(this);

    for (var decl in _decls) {
      Instance value;
      if (decl.initializer != null) value = globalInterpreter.evaluate(decl.initializer);

      if (decl.typename.lexeme == Constants.Dynamic) {
        instance.define(decl.varname.lexeme, decl.typename.lexeme, value: value);
      } else if (decl.typename.lexeme == Constants.Var) {
        // 如果用了var关键字，则从初始化表达式推断变量类型
        if (value != null) {
          instance.define(decl.varname.lexeme, value.type, value: value);
        } else {
          instance.define(decl.varname.lexeme, Constants.Dynamic);
        }
      } else {
        // 接下来define函数会判断类型是否符合声明
        instance.define(decl.varname.lexeme, decl.typename.lexeme, value: value);
      }
    }

    Subroutine constructorFunction;
    constructorName ??= name;

    try {
      constructorFunction = getMethod(constructorName);
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
    Constants.Null,
    superClass: htObject,
  );
}

class Instance extends Namespace {
  String get type => ofClass.name;

  @override
  String toString() => 'instance of class [${ofClass.name}]';

  final Class ofClass;

  Instance(this.ofClass);

  Instance fieldGet(String name) {
    if (defs.containsKey(name)) {
      return defs[name].value;
    } else {
      Subroutine method = ofClass.getMethod(name);
      return method.bind(this);
    }
  }

  void fieldSet(String name, Instance value) {
    if (defs.containsKey(name)) {
      var variableType = defs[name].type;
      if ((variableType == Constants.Dynamic) || (variableType == value.type)) {
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
  Constants.Object,
  superClass: null,
);

var htFunction = Class(
  Constants.Function,
  superClass: htObject,
);

var htNum = Class(
  Constants.Num,
  superClass: htObject,
);

var htBool = Class(
  Constants.Bool,
  superClass: htObject,
);

var htString = Class(
  Constants.Num,
  superClass: htObject,
);

class ConstNum extends Instance {
  num value;

  ConstNum(this.value) : super(htNum);
}

class ConstBool extends Instance {
  bool value;

  ConstBool(this.value) : super(htBool);
}

class ConstString extends Instance {
  String value;

  ConstString(this.value) : super(htString);
}
