import 'class.dart';
import 'common.dart';
import 'namespace.dart';
import 'statement.dart';
import 'interpreter.dart';
import 'errors.dart';

typedef HS_External = dynamic Function(HS_Instance instance, List<dynamic> args);

class HS_Function extends HS_Instance {
  @override
  String toString() => '$name(${type})';

  final String name;
  final FuncStmt funcStmt;
  final Namespace closure;
  final bool isConstructor;

  HS_External extern;

  int get arity {
    var a = -1;
    if (funcStmt != null) {
      a = funcStmt.params.length;
    }
    return a;
  }

  HS_Function(this.name, {this.funcStmt, this.closure, this.extern, this.isConstructor = false})
      : super(HS_Common.Function);

  HS_Function bind(HS_Instance instance) {
    Namespace namespace = Namespace(closure);
    namespace.define(HS_Common.This, instance.type, value: instance);
    return HS_Function(
      name,
      funcStmt: funcStmt,
      closure: namespace,
      extern: extern,
      isConstructor: isConstructor,
    );
  }

  dynamic call(List<dynamic> args) {
    try {
      if (extern != null) {
        var instance = closure?.fetchAt(0, HS_Common.This, report_exception: false);
        return extern(instance, args);
      } else {
        var environment = Namespace(closure);
        if (funcStmt != null) {
          if (args != null) {
            for (var i = 0; i < funcStmt.params.length; i++) {
              environment.define(funcStmt.params[i].varname.lexeme, funcStmt.params[i].typename.lexeme, value: args[i]);
            }
          }
          globalContext.executeBlock(funcStmt.definition, environment);
        } else {
          throw HSErr_MissingFuncDef(name);
        }
      }
    } catch (returnValue) {
      if ((returnValue is HS_Error) || (returnValue is Exception)) {
        throw returnValue;
      }

      String returned_type = HS_TypeOf(returnValue);

      if ((funcStmt != null) && (funcStmt.returnType != HS_Common.Dynamic) && (funcStmt.returnType != returned_type)) {
        throw HSErr_ReturnType(returned_type, name, funcStmt.returnType);
      }

      return returnValue;
    }

    if (isConstructor) {
      return closure.fetchAt(0, HS_Common.This);
    } else {
      return null;
    }
  }
}
