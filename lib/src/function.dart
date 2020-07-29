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

  String _savedBlockName;

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
    assert(args != null);
    try {
      if (extern != null) {
        var instance = closure?.fetchAt(0, HS_Common.This, error: false);
        return extern(globalInterpreter, instance, args ?? []);
      } else {
        var environment = Namespace(enclosing: closure);
        if (funcStmt != null) {
          if (arity >= 0) {
            if (arity != args.length) {
              throw HSErr_Arity(args.length, arity, funcStmt.name.line, funcStmt.name.column);
            } else {
              for (var i = 0; i < funcStmt.params.length; ++i) {
                var type_token = funcStmt.params[i].typename;
                var arg_type = HS_TypeOf(args[i]);
                if ((type_token.lexeme != HS_Common.Dynamic) &&
                    (type_token.lexeme != arg_type) &&
                    (arg_type != HS_Common.Null)) {
                  throw HSErr_ArgType(arg_type, type_token.lexeme, type_token.line, type_token.column);
                }
              }
            }
          }

          if (arity != -1) {
            for (var i = 0; i < funcStmt.params.length; i++) {
              environment.define(funcStmt.params[i].name.lexeme, funcStmt.params[i].typename.lexeme, value: args[i]);
            }
          } else {
            assert(funcStmt.params.length == 1);
            // “? args”形式的参数列表可以通过args这个List访问参数
            environment.define(funcStmt.params.first.name.lexeme, HS_Common.List, value: args);
          }
          _savedBlockName = globalInterpreter.curBlockName;
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

      if (_savedBlockName != null) {
        globalInterpreter.curBlockName = _savedBlockName;
        _savedBlockName = null;
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
