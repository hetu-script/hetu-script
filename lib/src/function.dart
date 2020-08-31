import 'class.dart';
import 'common.dart';
import 'namespace.dart';
import 'statement.dart';
import 'interpreter.dart';
import 'errors.dart';

typedef HS_External = dynamic Function(HS_Instance instance, List<dynamic> args);

class HS_Function extends HS_Namespace {
  @override
  String get type => HS_Common.Function;

  @override
  String toString() {
    String result = '${HS_Common.Function} $name(';
    if (funcStmt.arity >= 0) {
      for (var param in funcStmt.params) {
        result += param.name.lexeme + ': ' + (param.typename?.lexeme ?? HS_Common.Any);
        //if (param.initializer != null)
        if (funcStmt.params.length > 1) result += ', ';
      }
    } else {
      result += '...';
    }
    result += '): ' + funcStmt.returnType;
    return result;
  }

  final String name;
  final FuncStmt funcStmt;

  HS_External extern;

  HS_Function(this.funcStmt, {this.name, this.extern, HS_Namespace closure})
      : super(name: name ?? funcStmt.name.lexeme, closure: closure); //, line, column, fileName);

  // 成员函数需要绑定到实例
  HS_Function bind(HS_Instance instance, int line, int column, Interpreter interpreter) {
    return HS_Function(funcStmt, name: name, extern: extern, closure: instance);
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
                var init_value = interpreter.evaluateExpr(funcStmt.params[i].initializer);
                args.add(init_value);
              }
            }
          }
        }

        var instance = fetch(HS_Common.This, line, column, interpreter, nonExistError: false, from: closure.fullName);
        return extern(instance, args ?? []);
      } else {
        if (funcStmt != null) {
          if (funcStmt.arity >= 0) {
            if (args.length < funcStmt.arity) {
              throw HSErr_Arity(name, args.length, funcStmt.arity, line, column, interpreter.curFileName);
            } else if (args.length > funcStmt.params.length) {
              throw HSErr_Arity(name, args.length, funcStmt.params.length, line, column, interpreter.curFileName);
            } else {
              for (var i = 0; i < funcStmt.params.length; ++i) {
                // 考虑可选参数问题（"[]"内的参数不一定在调用时存在）
                var type_token = funcStmt.params[i].typename;
                var arg_type_decl;
                if (type_token != null) {
                  arg_type_decl = type_token.lexeme;
                } else {
                  arg_type_decl = HS_Common.Any;
                }

                if (i < args.length) {
                  var arg_type = HS_TypeOf(args[i]);
                  if ((arg_type_decl != HS_Common.Any) && (arg_type_decl != arg_type) && (arg_type != HS_Common.Null)) {
                    throw HSErr_ArgType(arg_type, arg_type_decl, line, column, interpreter.curFileName);
                  }

                  define(funcStmt.params[i].name.lexeme, arg_type_decl, line, column, interpreter, value: args[i]);
                } else {
                  var initializer = funcStmt.params[i].initializer;
                  var init_value;
                  if (initializer != null) init_value = interpreter.evaluateExpr(funcStmt.params[i].initializer);
                  define(funcStmt.params[i].name.lexeme, arg_type_decl, line, column, interpreter, value: init_value);
                }
              }
            }
          } else {
            // “...”形式的参数列表通过List访问参数
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
          (funcStmt.returnType != HS_Common.Any) &&
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
