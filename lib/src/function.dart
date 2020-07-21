import 'class.dart';
import 'common.dart';
import 'namespace.dart';
import 'statement.dart';
import 'interpreter.dart';
import 'errors.dart';

typedef Call = HS_Instance Function(List<HS_Instance> args);

abstract class Callable {}

class HS_Function extends HS_Instance {
  @override
  String toString() => '$name(${type})';

  final String name;
  final String className;
  final FuncStmt funcStmt;
  final Namespace closure;
  final bool isConstructor;

  Call bindFunc;

  int get arity {
    var a = -1;
    if (funcStmt != null) {
      a = funcStmt.params.length;
    }
    return a;
  }

  HS_Function(this.name, {this.className, this.funcStmt, this.closure, this.bindFunc, this.isConstructor = false})
      : super(HS_Common.Function);

  HS_Function bind(HS_Instance instance) {
    Namespace namespace = Namespace(closure);
    namespace.define(HS_Common.This, instance.type, value: instance);
    return HS_Function(
      name,
      funcStmt: funcStmt,
      closure: namespace,
      isConstructor: isConstructor,
    );
  }

  HS_Instance call(List<HS_Instance> args) {
    try {
      if (bindFunc != null) {
        return bindFunc(args);
      } else {
        var environment = Namespace(closure);
        if ((funcStmt != null) && (args != null)) {
          for (var i = 0; i < funcStmt.params.length; i++) {
            environment.define(funcStmt.params[i].varname.lexeme, funcStmt.params[i].typename.lexeme, value: args[i]);
          }
        }

        globalContext.executeBlock(funcStmt.definition, environment);
      }
    } catch (returnValue) {
      if (returnValue is HS_Instance) {
        if ((funcStmt != null) && (funcStmt.returnType != returnValue.type)) {
          throw HSErr_ReturnType(returnValue.type, name, funcStmt.returnType);
        }
        return returnValue;
      } else {
        throw returnValue;
      }
    }

    if (isConstructor) {
      return closure.fetchAt(0, HS_Common.This);
    } else {
      return null;
    }
  }
}
