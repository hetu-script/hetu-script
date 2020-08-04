import 'class.dart';
import 'common.dart';
import 'namespace.dart';
import 'statement.dart';
import 'interpreter.dart';
import 'errors.dart';

typedef HS_External = dynamic Function(HS_Instance instance, List<dynamic> args);

class HS_Function extends Namespace {
  @override
  String get type => HS_Common.FunctionObj;

  @override
  String toString() => '$name(${HS_Common.FunctionObj})';

  final String name;
  final FuncStmt funcStmt;

  HS_External extern;

  HS_Function(
      this.name, // int line, int column, String fileName,
      this.funcStmt,
      {this.extern,
      Namespace closure})
      : super(name: name, closure: closure); //, line, column, fileName);

  // 成员函数需要绑定到实例
  HS_Function enclose(Namespace closure, int line, int column, Interpreter interpreter) {
    if (closure is HS_Instance) closure.define(HS_Common.This, closure.type, line, column, interpreter, value: closure);
    return HS_Function(
        name, // line, column, fileName,
        funcStmt,
        extern: extern,
        closure: closure);
  }

  dynamic call(Interpreter interpreter, int line, int column, List<dynamic> args) {
    assert(args != null);
    try {
      if (extern != null) {
        if (funcStmt.arity != -1) {
          for (var i = 0; i < funcStmt.params.length; i++) {
            // 考虑可选参数问题（"[]"内的参数不一定在调用时存在）
            if (i >= args.length) {
              var initializer = funcStmt.params[i].initializer;
              if (initializer != null) {
                var init_value = globalInterpreter.evaluateExpr(funcStmt.params[i].initializer);
                args.add(init_value);
              }
            }
          }
        }

        var instance = fetch(HS_Common.This, line, column, interpreter, error: false, from: closure.fullName);
        return extern(instance, args ?? []);
      } else {
        //var environment = Namespace(
        //globalInterpreter.curFileName,
        //closure?.line, closure?.column, closure?.fileName,
        //closure: closure);
        if (funcStmt != null) {
          if (funcStmt.arity >= 0) {
            if (args.length < funcStmt.arity) {
              throw HSErr_Arity(name, args.length, funcStmt.arity, line, column, interpreter.curFileName);
            } else if (args.length > funcStmt.params.length) {
              throw HSErr_Arity(name, args.length, funcStmt.params.length, line, column, interpreter.curFileName);
            } else {
              for (var i = 0; i < funcStmt.params.length; ++i) {
                // 考虑可选参数问题（"[]"内的参数不一定在调用时存在）
                if (i < args.length) {
                  var type_token = funcStmt.params[i].typename;
                  var arg_type = HS_TypeOf(args[i]);
                  if ((type_token.lexeme != HS_Common.Dynamic) &&
                      (type_token.lexeme != arg_type) &&
                      (arg_type != HS_Common.Null)) {
                    throw HSErr_ArgType(arg_type, type_token.lexeme, line, column, interpreter.curFileName);
                  }
                }
              }
            }
          }

          if (funcStmt.arity != -1) {
            for (var i = 0; i < funcStmt.params.length; i++) {
              // 考虑可选参数问题（"[]"内的参数不一定在调用时存在）
              if (i < args.length) {
                define(funcStmt.params[i].name.lexeme, funcStmt.params[i].typename.lexeme, line, column, interpreter,
                    value: args[i]);
              } else {
                var initializer = funcStmt.params[i].initializer;
                var init_value;
                if (initializer != null) init_value = globalInterpreter.evaluateExpr(funcStmt.params[i].initializer);
                define(funcStmt.params[i].name.lexeme, funcStmt.params[i].typename.lexeme, line, column, interpreter,
                    value: init_value);
              }
            }
          } else {
            assert(funcStmt.params.length == 1);
            // “? args”形式的参数列表可以通过args这个List访问参数
            define(funcStmt.params.first.name.lexeme, HS_Common.List, line, column, interpreter, value: args);
          }
          interpreter.executeBlock(funcStmt.definition, this);
        } else {
          throw HSErr_MissingFuncDef(name, line, column, interpreter.curFileName);
        }
      }
    } catch (returnValue) {
      if (returnValue is HS_Error) {
        throw returnValue;
      } else if ((returnValue is Exception) || (returnValue is NoSuchMethodError)) {
        throw HS_Error(returnValue.toString(), line, column, interpreter.curFileName);
      }

      String returned_type = HS_TypeOf(returnValue);

      if ((funcStmt != null) &&
          (funcStmt.returnType != HS_Common.Dynamic) &&
          (returned_type != HS_Common.Null) &&
          (funcStmt.returnType != returned_type)) {
        throw HSErr_ReturnType(returned_type, name, funcStmt.returnType, line, column, interpreter.curFileName);
      }

      if (returnValue is NullThrownError) return null;
      return returnValue;
    }

    // if (functype == FuncStmtType.constructor) {
    //   return closure.fetch(HS_Common.This, line, column, fileName, from: closure.fullName);
    // } else {
    //   return null;
    // }
  }
}
