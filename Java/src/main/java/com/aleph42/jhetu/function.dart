import '../hetu.dart';
import 'class.dart';
import 'common.java';
import 'namespace.dart';
import 'statement.dart';
import 'interpreter.dart';
import 'errors.dart';
import 'value.dart';

// TODO: instance参数应该是可选的
typedef HS_External = dynamic Function(HS_Instance instance, List<dynamic> args);

class HS_TypeFunction extends HS_Type {
  final HS_Type returnType;
  final List<HS_Type> paramsTypes = [];

  HS_TypeFunction(this.returnType, {List<HS_Type> arguments, List<HS_Type> paramsTypes})
      : super(name: HS_Common.function, arguments: arguments) {
    if (paramsTypes != null) this.paramsTypes.addAll(paramsTypes);
  }

  @override
  String toString() {
    var result = StringBuffer();
    result.write('${name}');
    if (arguments.isNotEmpty) {
      result.write('<');
      for (var i = 0; i < arguments.length; ++i) {
        result.write(arguments[i]);
        if ((arguments.length > 1) && (i != arguments.length - 1)) result.write(', ');
      }
      result.write('>');
    }

    result.write('(');

    for (var param in paramsTypes) {
      result.write(param.name);
      //if (param.initializer != null)
      if (paramsTypes.length > 1) result.write(', ');
    }
    result.write('): ' + returnType.toString());
    return result.toString();
  }
}

class HS_Function {
  static int functionIndex = 0;

  final HS_Namespace declContext;
  HS_Namespace _closure;
  //HS_Namespace _save;
  final String internalName;
  String get name => internalName ?? funcStmt.name;

  final FuncStmt funcStmt;

  HS_TypeFunction _typeid;
  HS_TypeFunction get typeid => _typeid;

  final HS_External extern;

  HS_Function(this.funcStmt, {this.internalName, List<HS_Type> typeArgs, String name, this.extern, this.declContext}) {
    //_save = _closure = closure;

    var paramsTypes = <HS_Type>[];
    for (var param in funcStmt.params) {
      paramsTypes.add(param.declType);
    }

    _typeid = HS_TypeFunction(funcStmt.returnType, arguments: typeArgs, paramsTypes: paramsTypes);
  }

  @override
  String toString() {
    var result = StringBuffer();
    result.write('${HS_Common.function} ${name ?? ''}');
    if (typeid.arguments.isNotEmpty) {
      result.write('<');
      for (var i = 0; i < typeid.arguments.length; ++i) {
        result.write(typeid.arguments[i]);
        if ((typeid.arguments.length > 1) && (i != typeid.arguments.length - 1)) result.write(', ');
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

  dynamic call(Interpreter interpreter, int line, int column, List<dynamic> args, {HS_Instance instance}) {
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

        return extern(instance, args ?? []);
      } else {
        if (funcStmt != null) {
          //_save = _closure;
          //assert(closure != null);
          if (instance != null) {
            _closure = HS_Namespace(name: '__${instance.name}.${name}${functionIndex++}', closure: instance);
            _closure.define(HS_Common.THIS, instance.typeid, line, column, interpreter, mutable: false);
          } else {
            _closure = HS_Namespace(name: '__${name}${functionIndex++}', closure: declContext);
          }

          if (funcStmt.arity >= 0) {
            if (args.length < funcStmt.arity) {
              throw HSErr_Arity(name, args.length, funcStmt.arity, line, column, interpreter.curFileName);
            } else if (args.length > funcStmt.params.length) {
              throw HSErr_Arity(name, args.length, funcStmt.params.length, line, column, interpreter.curFileName);
            } else {
              for (var i = 0; i < funcStmt.params.length; ++i) {
                // 考虑可选参数问题（"[]"内的参数不一定在调用时存在）
                var var_stmt = funcStmt.params[i];
                HS_Type arg_type_decl = HS_Type();
                if (var_stmt.declType != null) {
                  arg_type_decl = var_stmt.declType;
                }

                if (i < args.length) {
                  var arg_type = HS_TypeOf(args[i]);
                  if (arg_type.isNotA(arg_type_decl)) {
                    throw HSErr_ArgType(args[i].toString(), arg_type.toString(), arg_type_decl.toString(), line, column,
                        interpreter.curFileName);
                  }

                  _closure.define(var_stmt.name.lexeme, arg_type_decl, line, column, interpreter, value: args[i]);
                } else {
                  var initializer = var_stmt.initializer;
                  dynamic init_value;
                  if (initializer != null) init_value = interpreter.evaluateExpr(var_stmt.initializer);
                  _closure.define(var_stmt.name.lexeme, arg_type_decl, line, column, interpreter, value: init_value);
                }
              }
            }
          } else {
            // “...”形式的参数列表通过List访问参数
            _closure.define(funcStmt.params.first.name.lexeme, HS_Type.list, line, column, interpreter, value: args);
          }

          interpreter.executeBlock(funcStmt.definition, _closure);
          //_closure = _save;
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

      if ((funcStmt != null) && (returned_type.isNotA(funcStmt.returnType))) {
        throw HSErr_ReturnType(
            returned_type.toString(), name, funcStmt.returnType.toString(), line, column, interpreter.curFileName);
      }

      if (returnValue is NullThrownError) return null;

      //_closure = _save;
      return returnValue;
    }

    return null;
  }
}
