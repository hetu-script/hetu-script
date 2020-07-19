import 'package:hetu_script/hetu.dart';

import 'environment.dart';
import 'statement.dart';
import 'interpreter.dart';
import 'constants.dart';
import 'errors.dart';
import 'token.dart';

//const _typeId = <String, int>{};

abstract class HetuObject {
  final String name;

  String get type;

  const HetuObject(this.name);

  @override
  String toString() => '[variable: "${name}", type: "${type}"]';

  static const Null = HetuNull();
}

class HetuNull extends HetuObject {
  @override
  String get type => Constants.Null;

  @override
  String toString() => Constants.Null;

  const HetuNull() : super(Constants.Null);
}

// TODO: 字面常量也是对象和实例，应该可以直接用“2.toString()”这种方式调用函数
class HetuNum extends HetuObject {
  @override
  String get type => Constants.Num;

  @override
  String toString() => literal.toString();

  num literal;
  HetuNum(num value) : super('${value}[${Constants.Num}]') {
    literal = value;
  }

  @override
  bool operator ==(dynamic other) => (other is HetuNum) && (literal == other.literal);
}

class HetuString extends HetuObject {
  @override
  String get type => Constants.Str;

  @override
  String toString() => literal;

  String literal;
  HetuString(String value) : super('${value}[${Constants.Str}]') {
    literal = value;
  }

  @override
  bool operator ==(dynamic other) => (other is HetuString) && (literal == other.literal);
}

class HetuBool extends HetuObject {
  @override
  String get type => Constants.Bool;

  @override
  String toString() => literal.toString();

  bool literal;
  HetuBool(bool value) : super('${value}[${Constants.Bool}]') {
    literal = value;
  }

  @override
  bool operator ==(dynamic other) => (other is HetuBool) && (literal == other.literal);
}

typedef HetuFunctionCall = HetuObject Function(List<HetuObject> args);

class HetuFunction extends HetuObject {
  @override
  String get type => _binded ? Constants.Method : Constants.Function;

  @override
  String toString() => '$name(${type})';

  bool _binded = false;

  final FuncStmt funcStmt;
  final Environment closure;
  final bool isConstructor;

  HetuFunctionCall call;

  int get arity {
    var a = -1;
    if (funcStmt != null) {
      a = funcStmt.params.length;
    }
    return a;
  }

  HetuFunction(String name, {this.funcStmt, this.closure, this.isConstructor, HetuFunctionCall call}) : super(name) {
    this.call = call ?? _call;
  }

  HetuFunction bind(HetuInstance instance) {
    _binded = true;
    Environment environment = Environment.enclose(closure);
    environment.define(Constants.This, instance.type, value: instance);
    return HetuFunction(
      name,
      funcStmt: funcStmt,
      closure: environment,
      isConstructor: isConstructor,
    );
  }

  HetuObject _call(List<HetuObject> args) {
    HetuObject result = HetuObject.Null;

    var environment = Environment.enclose(closure);

    if ((funcStmt != null) && (args != null)) {
      for (var i = 0; i < funcStmt.params.length; i++) {
        environment.declare(funcStmt.params[i].varname, funcStmt.params[i].typename.text, value: args[i]);
      }
    }

    try {
      globalInterpreter.executeBlock(funcStmt.definition, environment);
    } catch (returnValue) {
      if (returnValue is HetuObject) {
        result = returnValue;
        if ((funcStmt != null) && (funcStmt.returntype != result.type)) {
          throw HetuError(
              '(Object) A value of type "${result.type}" can\'t be returned from function "${name}" because it has a return type of "${funcStmt.returntype}".'
              ' [${funcStmt.name.lineNumber}, ${funcStmt.name.colNumber}].');
        }
        return result;
      } else {
        throw returnValue;
      }
    }

    if (isConstructor) {
      return closure.searchByName(0, Constants.This);
    }

    return result;
  }
}

class HetuClass extends HetuObject {
  @override
  String get type => Constants.Class;

  @override
  String toString() => '$name(class)';

  final HetuClass superClass;

  List<VarStmt> varStmts = [];
  Map<String, HetuFunction> methods = {};

  HetuClass(String name, this.superClass, this.varStmts, this.methods) : super(name);

  HetuObject getMethod(String name) {
    if (methods.containsKey(name)) {
      return methods[name];
    }

    if (superClass != null) {
      return superClass.getMethod(name);
    }

    return HetuObject.Null;
  }

  HetuInstance getInstance(List<HetuObject> args) {
    var instance = HetuInstance(this);
    for (var stmt in varStmts) {
      HetuObject value;
      if (stmt.initializer != null) {
        value = globalInterpreter.evaluate(stmt.initializer);
        if (value is HetuNull) {
          HetuError.add('(Interpreter) Don\'t explicitly initialize variables to null.'
              ' [${stmt.varname.lineNumber}, ${stmt.varname.colNumber}].');
        }
      }

      if (stmt.typename.text == Constants.Dynamic) {
        instance.declare(stmt.varname, stmt.typename.text, value: value);
      } else if (stmt.typename.text == Constants.Var) {
        // 如果用了var关键字，则从初始化表达式推断变量类型
        if (value != null) {
          instance.declare(stmt.varname, value.type, value: value);
        } else {
          instance.declare(stmt.varname, Constants.Dynamic);
        }
      } else {
        if (value != null) {
          instance.declare(stmt.varname, stmt.typename.text, value: value);
        } else {
          instance.declare(stmt.varname, stmt.typename.text);
        }
      }
    }

    HetuFunction constructor;

    try {
      constructor = getMethod(name);
    } catch (e) {
      if (e is! HetuErrorSymbolNotFound) {
        throw e;
      }
    } finally {
      if (constructor is HetuFunction) {
        constructor.bind(instance).call(args);
      }
    }

    return instance;
  }
}

class HetuInstance extends HetuObject {
  @override
  String get type => hetuClass.name;

  @override
  String toString() => '$name(instance of class [${hetuClass.name}])';

  final HetuClass hetuClass;
  Map<String, VarWrapper> variables = {};

  HetuInstance(this.hetuClass) : super('${hetuClass.name}${DateTime.now().millisecondsSinceEpoch}');

  HetuObject memberGetByName(String name) {
    if (variables.containsKey(name)) {
      return variables[name].value;
    } else {
      var field = hetuClass.getMethod(name);
      if (field is HetuFunction) {
        return field.bind(this);
      }
    }

    throw HetuErrorSymbolNotFound(name);
  }

  HetuObject memberGetByToken(Token name) {
    if (variables.containsKey(name.text)) {
      return variables[name.text].value;
    } else {
      var field = hetuClass.getMethod(name.text);
      if (field is HetuFunction) {
        return field.bind(this);
      }
    }

    throw HetuErrorSymbolNotFound(name.text, name.lineNumber, name.colNumber);
  }

  void declare(Token name, String type, {HetuObject value}) {
    if (!variables.containsKey(name.text)) {
      if ((type == Constants.Dynamic) || ((value != null) && (type == value.type)) || (value == null)) {
        variables[name.text] = VarWrapper(type, value: value);
      } else {
        throw HetuError('(Environment) Value type [${value.type}] doesn\'t match declared type [${type}].');
      }
    } else {
      throw HetuError('(Environment) Variable [${name.text}] is already declared.'
          ' [${name.lineNumber}, ${name.colNumber}].');
    }
  }

  void variableSet(Token name, HetuObject value) {
    if (variables.containsKey(name.text)) {
      var variableType = variables[name.text].type;
      if ((variableType == Constants.Dynamic) || (variableType == value.type)) {
        // 直接改写wrapper里面的值就行，不用重新生成wrapper
        variables[name.text].value = value;
      } else {
        throw HetuError(
            '(Environment) Assigned value type [${value.type}] doesn\'t match declared type [${variableType}].'
            ' [${name.lineNumber}, ${name.colNumber}].');
      }
    } else {
      throw HetuError('(object) Undefined property [${name.text}] of class [${hetuClass.name}], '
          ' [${name.lineNumber}, ${name.colNumber}].');
    }
  }
}
