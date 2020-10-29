import 'class.dart';
import 'binding.dart' show HT_External;
import 'namespace.dart';
import 'statement.dart';
import 'interpreter.dart';
import 'errors.dart';
import 'value.dart';
import 'lexicon.dart';

class HT_FunctionType extends HT_Type {
  final HT_Type returnType;
  final List<HT_Type> paramsTypes;

  HT_FunctionType(this.returnType, {List<HT_Type> arguments = const [], this.paramsTypes = const []})
      : super(HT_Lexicon.function, arguments: arguments);

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

    for (final param in paramsTypes) {
      result.write(param.name);
      //if (param.initializer != null)
      if (paramsTypes.length > 1) result.write(', ');
    }
    result.write('): ' + returnType.toString());
    return result.toString();
  }
}

class HT_Function {
  static int functionIndex = 0;

  HT_Namespace declContext;
  HT_Namespace _closure;
  //HT_Namespace _save;
  final String internalName;
  String get name => internalName ?? funcStmt.name;

  final FuncDeclStmt funcStmt;

  HT_FunctionType _typeid;
  HT_FunctionType get typeid => _typeid;

  final HT_External extern;

  HT_Function(this.funcStmt, {this.internalName, List<HT_Type> typeArgs = const [], this.extern, this.declContext}) {
    //_save = _closure = closure;

    var paramsTypes = <HT_Type>[];
    for (final param in funcStmt.params) {
      paramsTypes.add(param.declType ?? HT_Type.ANY);
    }

    _typeid = HT_FunctionType(funcStmt.returnType, arguments: typeArgs, paramsTypes: paramsTypes);
  }

  @override
  String toString() {
    var result = StringBuffer();
    result.write('${HT_Lexicon.function} ${name ?? ''}');
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
      for (final param in funcStmt.params) {
        result.write(param.name.lexeme + ': ' + (param.declType?.toString() ?? HT_Lexicon.ANY));
        //if (param.initializer != null)
        if (funcStmt.params.length > 1) result.write(', ');
      }
    } else {
      result.write('... ');
      result.write(funcStmt.params.first.name.lexeme + ': ' + (funcStmt.params.first.declType ?? HT_Lexicon.ANY));
    }
    result.write('): ' + funcStmt.returnType?.toString() ?? HT_Lexicon.VOID);
    return result.toString();
  }

  dynamic call(Interpreter interpreter, int line, int column, List<dynamic> args, {HT_Instance instance}) {
    assert(args != null);
    dynamic result;
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
            _closure = HT_Namespace(name: '__${instance.name}.${name}${functionIndex++}', closure: instance);
            _closure.define(HT_Lexicon.THIS, interpreter,
                declType: instance.typeid, line: line, column: column, isMutable: false);
          } else {
            _closure = HT_Namespace(name: '__${name}${functionIndex++}', closure: declContext);
          }

          if (funcStmt.arity >= 0) {
            if (args.length < funcStmt.arity) {
              throw HTErr_Arity(name, args.length, funcStmt.arity, line, column, interpreter.curFileName);
            } else if (args.length > funcStmt.params.length) {
              throw HTErr_Arity(name, args.length, funcStmt.params.length, line, column, interpreter.curFileName);
            } else {
              for (var i = 0; i < funcStmt.params.length; ++i) {
                // 考虑可选参数问题（"[]"内的参数不一定在调用时存在）
                final var_stmt = funcStmt.params[i];
                final arg_type_decl = var_stmt.declType;

                dynamic arg_value;
                if (i < args.length) {
                  var arg_type = HT_TypeOf(args[i]);
                  if (arg_type.isNotA(arg_type_decl)) {
                    throw HTErr_ArgType(args[i].toString(), arg_type.toString(), arg_type_decl.toString(), line, column,
                        interpreter.curFileName);
                  }

                  arg_value = args[i];
                } else {
                  if (var_stmt.initializer != null) arg_value = interpreter.evaluateExpr(var_stmt.initializer);
                }

                _closure.define(var_stmt.name.lexeme, interpreter,
                    declType: arg_type_decl, line: line, column: column, value: arg_value);
              }
            }
          } else {
            // “...”形式的参数列表通过List访问参数
            _closure.define(funcStmt.params.first.name.lexeme, interpreter,
                declType: HT_Type.list, line: line, column: column, value: args);
          }

          result = interpreter.executeBlock(funcStmt.definition, _closure);
          //_closure = _save;
        } else {
          throw HTErr_MissingFuncDef(name, line, column, interpreter.curFileName);
        }
      }
    } catch (returnValue) {
      if (returnValue is HT_Error) {
        rethrow;
      } else if ((returnValue is Exception) || (returnValue is NoSuchMethodError)) {
        throw HT_Error(returnValue.toString(), line, column, interpreter.curFileName);
      }

      var returned_type = HT_TypeOf(returnValue);

      if ((funcStmt != null) && (returned_type.isNotA(funcStmt.returnType))) {
        throw HTErr_ReturnType(
            returned_type.toString(), name, funcStmt.returnType.toString(), line, column, interpreter.curFileName);
      }

      if (returnValue is NullThrownError) return null;

      //_closure = _save;
      return returnValue;
    }

    return result;
  }
}
