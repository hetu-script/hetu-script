import 'class.dart';
import 'namespace.dart';
import 'errors.dart';
import 'type.dart';
import 'lexicon.dart';
import 'expression.dart';
import 'ast_interpreter.dart';

class HT_FunctionType extends HT_TypeId {
  final HT_TypeId returnType;
  final List<HT_TypeId> paramsTypes;

  HT_FunctionType(this.returnType, {List<HT_TypeId> arguments = const [], this.paramsTypes = const []})
      : super(HT_Lexicon.function, arguments: arguments);

  @override
  String toString() {
    var result = StringBuffer();
    result.write('$id');
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
      result.write(param.id);
      //if (param.initializer != null)
      if (paramsTypes.length > 1) result.write(', ');
    }
    result.write('): ' + returnType.toString());
    return result.toString();
  }
}

class HT_Function with HT_Type, ASTInterpreterRef {
  static int functionIndex = 0;

  HT_Namespace declContext;
  late HT_Namespace _closure;
  //HT_Namespace _save;
  String get id => funcStmt.id?.lexeme ?? '';
  String get internalName => funcStmt.internalName;

  final FuncDeclaration funcStmt;

  late final HT_FunctionType _typeid;
  @override
  HT_TypeId get typeid => _typeid;

  final bool isExtern;

  HT_Function(this.funcStmt, this.declContext, HT_ASTInterpreter interpreter,
      {List<HT_TypeId> typeArgs = const [], this.isExtern = false}) {
    //_save = _closure = closure;
    this.interpreter = interpreter;

    var paramsTypes = <HT_TypeId>[];
    for (final param in funcStmt.params) {
      paramsTypes.add(param.declType);
    }
    _typeid = HT_FunctionType(funcStmt.returnType, arguments: typeArgs, paramsTypes: paramsTypes);
  }

  @override
  String toString() {
    var result = StringBuffer();
    result.write('${HT_Lexicon.function}');
    result.write(' $id');
    if (typeid.arguments.isNotEmpty) {
      result.write('<');
      for (var i = 0; i < typeid.arguments.length; ++i) {
        result.write(typeid.arguments[i]);
        if ((typeid.arguments.length > 1) && (i != typeid.arguments.length - 1)) result.write(', ');
      }
      result.write('>');
    }

    result.write('(');

    for (final param in funcStmt.params) {
      if (param.isVariadic) {
        result.write(HT_Lexicon.varargs + ' ');
      }
      result.write(param.id.lexeme + ': ' + (param.declType.toString()));
      //if (param.initializer != null)
      if (funcStmt.params.length > 1) result.write(', ');
    }
    result.write('): ' + funcStmt.returnType.toString());
    return result.toString();
  }

  dynamic call(
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HT_Instance? instance}) {
    if (positionalArgs.length < funcStmt.arity ||
        (positionalArgs.length > funcStmt.params.length && !funcStmt.isVariadic)) {
      throw HT_Error_Arity(id, positionalArgs.length, funcStmt.arity);
    }

    dynamic result;
    try {
      if (funcStmt.definition != null) {
        //_save = _closure;
        //assert(closure != null);
        // 函数每次在调用时，才生成对应的作用域
        if (instance != null) {
          _closure = HT_Namespace(interpreter, id: '__${instance.id}.$id${functionIndex++}', closure: instance);
          _closure.define(HT_Lexicon.THIS, declType: instance.typeid, isImmutable: true);
        } else {
          _closure = HT_Namespace(interpreter, id: '__$id${functionIndex++}', closure: declContext);
        }

        for (var i = 0; i < funcStmt.params.length; ++i) {
          var param = funcStmt.params[i];

          if (funcStmt.params[i].isOptional &&
              (i >= positionalArgs.length) &&
              (funcStmt.params[i].initializer != null)) {
            positionalArgs.add(interpreter.evaluateExpr(funcStmt.params[i].initializer!));
          } else if (funcStmt.params[i].isNamed &&
              (namedArgs[funcStmt.params[i].id.lexeme] == null) &&
              (funcStmt.params[i].initializer != null)) {
            namedArgs[funcStmt.params[i].id.lexeme] = interpreter.evaluateExpr(funcStmt.params[i].initializer!);
          }

          var arg;
          if (!param.isNamed) {
            arg = positionalArgs[i];
          } else {
            arg = namedArgs[param.id as String];
          }
          final arg_type_decl = param.declType;

          if (!param.isVariadic) {
            var arg_type = HT_TypeOf(arg);
            if (arg_type.isNotA(arg_type_decl)) {
              throw HT_Error_ArgType(arg.toString(), arg_type.toString(), arg_type_decl.toString());
            }
            _closure.define(param.id.lexeme, declType: arg_type_decl, value: arg);
          } else {
            var varargs = [];
            for (var j = i; j < positionalArgs.length; ++j) {
              arg = positionalArgs[j];
              var arg_type = HT_TypeOf(arg);
              if (arg_type.isNotA(arg_type_decl)) {
                throw HT_Error_ArgType(arg.toString(), arg_type.toString(), arg_type_decl.toString());
              }
              varargs.add(arg);
            }
            _closure.define(param.id.lexeme, declType: HT_TypeId.list, value: varargs);
            break;
          }
        }

        result = interpreter.executeBlock(funcStmt.definition!, _closure);
        //_closure = _save;
      } else {
        throw HT_Error_MissingFuncDef(id);
      }
    } catch (returnValue) {
      if ((returnValue is HT_Error) || (returnValue is Exception) || (returnValue is Error)) {
        rethrow;
      }

      var returned_type = HT_TypeOf(returnValue);

      if (returned_type.isNotA(funcStmt.returnType)) {
        throw HT_Error_ReturnType(returned_type.toString(), id, funcStmt.returnType.toString());
      }

      if (returnValue is NullThrownError) return null;

      //_closure = _save;
      return returnValue;
    }

    // 如果函数体中没有直接return，则会返回最后一个语句的值
    return result;
  }
}
