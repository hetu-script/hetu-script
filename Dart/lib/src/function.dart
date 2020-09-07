import 'class.dart';
import 'common.dart';
import 'namespace.dart';
import 'statement.dart';
import 'interpreter.dart';
import 'errors.dart';
import 'value.dart';

typedef HS_External = dynamic Function(HS_Instance instance, List<dynamic> args);

class HS_TypeFunction extends HS_Type {}

class HS_Function extends HS_Namespace {
  final FuncStmt funcStmt;
  final List<HS_Type> typeArgs = [];

  HS_Function type;

  String toString() {
    var result = StringBuffer();
    result.write('${HS_Common.function} ${name ?? ''}');
    if (typeArgs.isNotEmpty) {
      result.write('<');
      for (var i = 0; i < typeArgs.length; ++i) {
        result.write(typeArgs[i]);
        if ((typeArgs.length > 1) && (i != typeArgs.length - 1)) result.write(', ');
      }
      result.write('>');
    }

    result.write('(');

    if (funcStmt.arity >= 0) {
      for (var param in funcStmt.params) {
        result.write(param.name.lexeme + ': ' + (param.declType?.toString() ?? HS_Common.ANY));
        //if (param.initializer != null)
        if (funcStmt.params.length > 1) result.write(', ');
      }
    } else {
      result.write('(... ');
      result.write(funcStmt.params.first.name.lexeme + ': ' + (funcStmt.params.first.declType ?? HS_Common.ANY));
    }
    result.write('): ' + funcStmt.returnType?.toString() ?? HS_Common.VOID);
    return result.toString();
  }

  HS_External extern;

  HS_Function(this.funcStmt, {String name, this.extern, HS_Namespace closure})
      : super(name: name ?? funcStmt.name, closure: closure) {
    for (var param in funcStmt.params) {
      typeArgs.add(param.declType);
    }
  }

  // 成员函数需要绑定到实例
  HS_Function bind(HS_Instance instance, int line, int column, Interpreter interpreter) {
    return HS_Function(funcStmt, name: name, extern: extern, closure: instance);
  }

  dynamic call(Interpreter interpreter, int line, int column, List<dynamic> args) {
    assert(args != null);
    try {
      if (extern != null) {
        if (funcStmt.arity != -1) {
          for (var i = 0; i < funcStmt.params.length; ++i) {
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

        var instance = fetch(HS_Common.THIS, line, column, interpreter, nonExistError: false, from: closure.fullName);
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
                var var_stmt = funcStmt.params[i];
                HS_Type arg_type_decl;
                if (var_stmt.declType != null) {
                  arg_type_decl = var_stmt.declType;
                } else {
                  arg_type_decl = HS_Type.any;
                }

                if (i < args.length) {
                  var arg_type = HS_TypeOf(args[i]);
                  if ((arg_type_decl != HS_Common.ANY) && (arg_type_decl != arg_type) && (arg_type != null)) {
                    throw HSErr_ArgType(
                        arg_type.toString(), arg_type_decl.toString(), line, column, interpreter.curFileName);
                  }

                  define(var_stmt.name.lexeme, arg_type_decl, line, column, interpreter, value: args[i]);
                } else {
                  var initializer = var_stmt.initializer;
                  var init_value;
                  if (initializer != null) init_value = interpreter.evaluateExpr(var_stmt.initializer);
                  define(var_stmt.name.lexeme, arg_type_decl, line, column, interpreter, value: init_value);
                }
              }
            }
          } else {
            // “...”形式的参数列表通过List访问参数
            define(funcStmt.params.first.name.lexeme, HS_Type.list, line, column, interpreter, value: args);
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

      var returned_type = HS_TypeOf(returnValue);

      if ((funcStmt != null) &&
          (funcStmt.returnType != HS_Common.ANY) &&
          (returned_type != null) &&
          (funcStmt.returnType != returned_type)) {
        throw HSErr_ReturnType(
            returned_type.toString(), name, funcStmt.returnType.toString(), line, column, interpreter.curFileName);
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
