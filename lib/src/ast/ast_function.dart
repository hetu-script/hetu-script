import 'package:hetu_script/src/common.dart';
import 'package:hetu_script/src/object.dart';

import '../instance.dart';
import '../namespace.dart';
import '../errors.dart';
import '../type.dart';
import '../lexicon.dart';
import 'ast.dart';
import 'ast_interpreter.dart';
import '../variable.dart';
import '../function.dart';
import '../object.dart';

class HTAstFunction extends HTFunction with AstInterpreterRef {
  final FuncDeclStmt funcStmt;

  HTAstFunction(
      this.funcStmt, HTAstInterpreter interpreter, String moduleUniqueKey,
      {String? externalTypedef,
      List<HTType> typeArgs = const [],
      HTNamespace? context})
      : super(
          funcStmt.internalName,
          funcStmt.id?.lexeme ?? '', moduleUniqueKey,
          // classId: funcStmt.classId,
          funcType: funcStmt.funcType,
          externalFunctionType: ExternalFunctionType.none, // TODO: 这里需要修改
          externalTypedef: externalTypedef,
          typeArgs: typeArgs,
          // type:
          isConst: funcStmt.isConst,
          isVariadic: funcStmt.isVariadic,
          minArity: funcStmt.arity,
        ) {
    this.interpreter = interpreter;
    this.context = context;

    // TODO: 参数改成声明，这里才能创建类型
    // type = HTFunctionType(
    //     returnType: funcStmt.returnType, positionalParameterTypes: paramsTypes);
  }

  @override
  String toString() {
    var result = StringBuffer();
    result.write('${HTLexicon.function}');
    result.write(' $id');
    if (rtType.typeArgs.isNotEmpty) {
      result.write('<');
      for (var i = 0; i < rtType.typeArgs.length; ++i) {
        result.write(rtType.typeArgs[i]);
        if ((rtType.typeArgs.length > 1) && (i != rtType.typeArgs.length - 1)) {
          result.write(', ');
        }
      }
      result.write('>');
    }

    result.write('(');

    for (final param in funcStmt.params) {
      if (param.isVariadic) {
        result.write(HTLexicon.varargs + ' ');
      }
      result.write(param.id.lexeme + ': ' + (param.declType.toString()));
      //if (param.initializer != null)
      if (funcStmt.params.length > 1) result.write(', ');
    }
    result.write(') -> ' + funcStmt.returnType.toString());
    return result.toString();
  }

  @override
  dynamic call(
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = false}) {
    HTFunction.callStack.add(id);

    if (positionalArgs.length < funcStmt.arity ||
        (positionalArgs.length > funcStmt.params.length &&
            !funcStmt.isVariadic)) {
      throw HTError.arity(id, positionalArgs.length, funcStmt.arity);
    }

    dynamic result;
    try {
      if (funcStmt.definition != null) {
        // 函数每次在调用时，临时生成一个新的作用域
        final closure = HTNamespace(interpreter, closure: context);
        if (context is HTInstance) {
          closure.define(HTVariable(HTLexicon.THIS, value: context));
        }

        // TODO: 参数也改成Declaration而不是DeclStmt？
        for (var i = 0; i < funcStmt.params.length; ++i) {
          var param = funcStmt.params[i];

          if (funcStmt.params[i].isOptional &&
              (i >= positionalArgs.length) &&
              (funcStmt.params[i].initializer != null)) {
            positionalArgs
                .add(interpreter.visitASTNode(funcStmt.params[i].initializer!));
          } else if (funcStmt.params[i].isNamed &&
              (namedArgs[funcStmt.params[i].id.lexeme] == null) &&
              (funcStmt.params[i].initializer != null)) {
            namedArgs[funcStmt.params[i].id.lexeme] =
                interpreter.visitASTNode(funcStmt.params[i].initializer!);
          }

          var arg;
          if (!param.isNamed) {
            arg = positionalArgs[i];
          } else {
            arg = namedArgs[param.id.lexeme];
          }
          final argTypeid = param.declType ?? HTType.ANY;

          if (!param.isVariadic) {
            final argEncapsulation = interpreter.encapsulate(arg);
            if (argEncapsulation.rtType.isNotA(argTypeid)) {
              final arg_type = interpreter.encapsulate(arg).rtType;
              throw HTError.argType(
                  arg.toString(), arg_type.toString(), argTypeid.toString());
            }
            closure.define(HTVariable(param.id.lexeme, value: arg));
          } else {
            var varargs = [];
            for (var j = i; j < positionalArgs.length; ++j) {
              arg = positionalArgs[j];
              final argEncapsulation = interpreter.encapsulate(arg);
              if (argEncapsulation.rtType.isNotA(argTypeid)) {
                final arg_type = interpreter.encapsulate(arg).rtType;
                throw HTError.argType(
                    arg.toString(), arg_type.toString(), argTypeid.toString());
              }
              varargs.add(arg);
            }
            closure.define(HTVariable(param.id.lexeme, value: varargs));
            break;
          }
        }

        result = interpreter.executeBlock(funcStmt.definition!, closure);
      } else {
        throw HTError.missingFuncDef(id);
      }
    } catch (returnValue) {
      if ((returnValue is HTError) ||
          (returnValue is Exception) ||
          (returnValue is Error)) {
        rethrow;
      }

      final encapsulation = interpreter.encapsulate(result);
      if (encapsulation.rtType.isNotA(returnType)) {
        throw HTError.returnType(
            encapsulation.rtType.toString(), id, returnType.toString());
      }

      if (returnValue is! NullThrownError && returnValue != HTObject.NULL) {
        result = returnValue;
      }

      HTFunction.callStack.removeLast();
      return result;
    }

    // 这里不能用finally，会导致异常无法继续抛出
    HTFunction.callStack.removeLast();
    return result;
  }

  @override
  HTAstFunction clone() => HTAstFunction(funcStmt, interpreter, moduleUniqueKey,
      externalTypedef: externalTypedef, typeArgs: typeArgs, context: context);
}
