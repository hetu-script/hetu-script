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

  HS_FuncObj(this.name, int line, int column,
      {this.className, this.funcStmt, this.closure, this.extern, this.functype = FuncStmtType.normal, this.arity = 0})
      : super(HS_Common.FunctionObj, line, column);

  // 成员函数外层是实例
  HS_FuncObj bind(HS_Instance instance) {
    Namespace namespace = Namespace(instance.line, instance.column, enclosing: instance);
    namespace.define(HS_Common.This, instance.type, line, column, value: instance);
    return HS_FuncObj(name, line, column,
        className: className, funcStmt: funcStmt, closure: namespace, extern: extern, functype: functype, arity: arity);
  }

  dynamic call(List<dynamic> args) {
    assert(args != null);
    try {
      if (extern != null) {
        var instance = closure?.fetchAt(0, HS_Common.This, line, column, error: false);
        return extern(globalInterpreter, instance, args ?? []);
      } else {
        var environment = Namespace(closure?.line, closure?.column, enclosing: closure);
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
              environment.define(funcStmt.params[i].name.lexeme, funcStmt.params[i].typename.lexeme, line, column,
                  value: args[i]);
            }
          } else {
            assert(funcStmt.params.length == 1);
            // “? args”形式的参数列表可以通过args这个List访问参数
            environment.define(funcStmt.params.first.name.lexeme, HS_Common.List, line, column, value: args);
          }
          _savedBlockName = globalInterpreter.curBlockName;
          globalInterpreter.curBlockName = closure.blockName;
          globalInterpreter.executeBlock(funcStmt.definition, environment);
        } else {
          throw HSErr_MissingFuncDef(name, line, column);
        }
      }
    } catch (returnValue) {
      if (returnValue is HS_Error) {
        throw returnValue;
      } else if ((returnValue is Exception) || (returnValue is NoSuchMethodError)) {
        throw HS_Error(returnValue.toString(), line, column);
      }

      String returned_type = HS_TypeOf(returnValue);

      if ((funcStmt != null) &&
          (funcStmt.returnType != HS_Common.Dynamic) &&
          (returned_type != HS_Common.Null) &&
          (funcStmt.returnType != returned_type)) {
        throw HSErr_ReturnType(returned_type, name, funcStmt.returnType, line, column);
      }

      if (_savedBlockName != null) {
        globalInterpreter.curBlockName = _savedBlockName;
        _savedBlockName = null;
      }

      if (returnValue is NullThrownError) return null;
      return returnValue;
    }

    if (functype == FuncStmtType.constructor) {
      return closure.fetchAt(0, HS_Common.This, line, column);
    } else {
      return null;
    }
  }
}
