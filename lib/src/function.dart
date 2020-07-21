import 'class.dart';
import 'common.dart';
import 'namespace.dart';
import 'statement.dart';
import 'interpreter.dart';
import 'errors.dart';

typedef Call = Instance Function(List<Instance> args);

abstract class Callable {}

class Subroutine extends Instance {
  @override
  String toString() => '$name(${type})';

  final String name;

  final FuncStmt funcStmt;
  final Namespace closure;
  final bool isConstructor;

  //TODO: external关键字表明函数绑定到了脚本环境之外
  Call extern;

  int get arity {
    var a = -1;
    if (funcStmt != null) {
      a = funcStmt.params.length;
    }
    return a;
  }

  Subroutine(this.name, {this.funcStmt, this.closure, this.extern, this.isConstructor = false}) : super(htFunction);

  Subroutine bind(Instance instance) {
    Namespace namespace = Namespace(closure);
    namespace.define(Common.This, instance.type, value: instance);
    return Subroutine(
      name,
      funcStmt: funcStmt,
      closure: namespace,
      isConstructor: isConstructor,
    );
  }

  Instance call(List<Instance> args) {
    Instance result;

    try {
      if (extern == null) {
        var environment = Namespace(closure);
        if ((funcStmt != null) && (args != null)) {
          for (var i = 0; i < funcStmt.params.length; i++) {
            environment.define(funcStmt.params[i].varname.lexeme, funcStmt.params[i].typename.lexeme, value: args[i]);
          }
        }

        globalContext.executeBlock(funcStmt.definition, environment);
      } else {
        result = extern(args);
      }
    } catch (returnValue) {
      if (returnValue is Instance) {
        result = returnValue;
        if ((funcStmt != null) && (funcStmt.returntype != result.type)) {
          throw HetuErrorReturnType(result.type, name, funcStmt.returntype);
        }
        return result;
      } else {
        throw returnValue;
      }
    }

    if (isConstructor) {
      return closure.fetchAt(0, Common.This);
    }

    return result;
  }
}
