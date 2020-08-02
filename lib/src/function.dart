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

  Namespace _saved;

  HS_External extern;

  final int arity;

  HS_FuncObj(this.name, // int line, int column, String file_name,
      {this.className,
      this.funcStmt,
      this.closure,
      this.extern,
      this.functype = FuncStmtType.normal,
      this.arity = 0})
      : super(globalInterpreter.fetchGlobal(
            HS_Common.FunctionObj, null, null, globalInterpreter.curFileName)); //, line, column, file_name);

  // 成员函数外层是实例
  HS_FuncObj bind(HS_Instance instance, int line, int column, String file_name) {
    Namespace namespace = Namespace(globalInterpreter.curFileName,
        //instance.line, instance.column, instance.file_name,
        enclosing: instance);
    namespace.define(HS_Common.This, instance.type, line, column, file_name, value: instance);
    return HS_FuncObj(name, // line, column, file_name,
        className: className,
        funcStmt: funcStmt,
        closure: namespace,
        extern: extern,
        functype: functype,
        arity: arity);
  }

  dynamic call(int line, int column, String file_name, List<dynamic> args) {
    assert(args != null);
    try {
      if (extern != null) {
        var instance = closure?.fetchAt(0, HS_Common.This, line, column, file_name, error: false);
        return extern(globalInterpreter, instance, args ?? []);
      } else {
        var environment = Namespace(globalInterpreter.curFileName,
            //closure?.line, closure?.column, closure?.file_name,
            enclosing: closure);
        if (funcStmt != null) {
          if (arity >= 0) {
            if (args.length < arity) {
              throw HSErr_Arity(name, args.length, arity, line, column, file_name);
            } else if (args.length > funcStmt.params.length) {
              throw HSErr_Arity(name, args.length, funcStmt.params.length, line, column, file_name);
            } else {
              for (var i = 0; i < funcStmt.params.length; ++i) {
                // 考虑可选参数问题（"[]"内的参数不一定在调用时存在）
                if (i < args.length) {
                  var type_token = funcStmt.params[i].typename;
                  var arg_type = HS_TypeOf(args[i]);
                  if ((type_token.lexeme != HS_Common.Dynamic) &&
                      (type_token.lexeme != arg_type) &&
                      (arg_type != HS_Common.Null)) {
                    throw HSErr_ArgType(arg_type, type_token.lexeme, line, column, file_name);
                  }
                }
              }
            }
          }

          if (arity != -1) {
            for (var i = 0; i < funcStmt.params.length; i++) {
              // 考虑可选参数问题（"[]"内的参数不一定在调用时存在）
              if (i < args.length) {
                environment.define(
                    funcStmt.params[i].name.lexeme, funcStmt.params[i].typename.lexeme, line, column, file_name,
                    value: args[i]);
              } else {
                var initializer = funcStmt.params[i].initializer;
                var init_value;
                if (initializer != null) init_value = globalInterpreter.evaluateExpr(funcStmt.params[i].initializer);
                environment.define(
                    funcStmt.params[i].name.lexeme, funcStmt.params[i].typename.lexeme, line, column, file_name,
                    value: init_value);
              }
            }
          } else {
            assert(funcStmt.params.length == 1);
            // “? args”形式的参数列表可以通过args这个List访问参数
            environment.define(funcStmt.params.first.name.lexeme, HS_Common.List, line, column, file_name, value: args);
          }
          _saved = globalInterpreter.curContext;
          globalInterpreter.executeBlock(funcStmt.definition, environment);
        } else {
          throw HSErr_MissingFuncDef(name, line, column, file_name);
        }
      }
    } catch (returnValue) {
      if (returnValue is HS_Error) {
        throw returnValue;
      } else if ((returnValue is Exception) || (returnValue is NoSuchMethodError)) {
        throw HS_Error(returnValue.toString(), line, column, file_name);
      }

      String returned_type = HS_TypeOf(returnValue);

      if ((funcStmt != null) &&
          (funcStmt.returnType != HS_Common.Dynamic) &&
          (returned_type != HS_Common.Null) &&
          (funcStmt.returnType != returned_type)) {
        throw HSErr_ReturnType(returned_type, name, funcStmt.returnType, line, column, file_name);
      }

      if (_saved != null) {
        globalInterpreter.curContext = _saved;
        _saved = null;
      }

      if (returnValue is NullThrownError) return null;
      return returnValue;
    }

    if (functype == FuncStmtType.constructor) {
      return closure.fetchAt(0, HS_Common.This, line, column, file_name);
    } else {
      return null;
    }
  }
}
