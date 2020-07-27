import 'class.dart';
import 'common.dart';
import 'namespace.dart';
import 'statement.dart';
import 'interpreter.dart';
import 'errors.dart';

typedef HS_External = dynamic Function(Interpreter interpreter, HS_Instance instance, List<dynamic> args);

class HS_FuncObj extends HS_Instance {
  @override
  String toString() => '$name(${type})';

  final String name;
  final String className;
  final FuncStmt funcStmt;
  final Namespace closure;
  final FuncStmtType functype;

  HS_External extern;

  final int arity;

  HS_FuncObj(this.name,
      {this.className, this.funcStmt, this.closure, this.extern, this.functype = FuncStmtType.normal, this.arity = 0})
      : super(HS_Common.FunctionObj);

  // 成员函数外层是实例
  HS_FuncObj bind(HS_Instance instance) {
    Namespace namespace = Namespace(enclosing: instance);
    namespace.define(HS_Common.This, instance.type, value: instance);
    return HS_FuncObj(name,
        className: className, funcStmt: funcStmt, closure: namespace, extern: extern, functype: functype, arity: arity);
  }

  dynamic call(List<dynamic> args) {
    try {
      if (extern != null) {
        var instance = closure?.fetchAt(0, HS_Common.This, error: false);
        return extern(globalInterpreter, instance, args ?? []);
      } else {
        var environment = Namespace(enclosing: closure);
        if (funcStmt != null) {
          if (args != null) {
            if (arity != -1) {
              for (var i = 0; i < funcStmt.params.length; i++) {
                environment.define(funcStmt.params[i].name.lexeme, funcStmt.params[i].typename.lexeme, value: args[i]);
              }
            } else {}
          }
          globalInterpreter.curBlockName = closure.blockName;
          globalInterpreter.executeBlock(funcStmt.definition, environment);
        } else {
          throw HSErr_MissingFuncDef(name);
        }
      }
    } catch (returnValue) {
      if ((returnValue is HS_Error) || (returnValue is Exception)) {
        throw returnValue;
      }

      String returned_type = HS_TypeOf(returnValue);

      if ((funcStmt != null) &&
          (funcStmt.returnType != HS_Common.Dynamic) &&
          (returned_type != HS_Common.Null) &&
          (funcStmt.returnType != returned_type)) {
        throw HSErr_ReturnType(returned_type, name, funcStmt.returnType);
      }

      if (returnValue is NullThrownError) return null;
      return returnValue;
    }

    if (functype == FuncStmtType.constructor) {
      return closure.fetchAt(0, HS_Common.This);
    } else {
      return null;
    }
  }
}
