import 'package:hetu_script/src/object.dart';

import '../class.dart';
import '../namespace.dart';
import '../errors.dart';
import '../type.dart';
import '../lexicon.dart';
import 'ast.dart';
import 'ast_interpreter.dart';
import '../declaration.dart';
import '../function.dart';
import '../object.dart';

class HTAstFunction extends HTFunction with AstInterpreterRef {
  final FuncDeclStmt funcStmt;

  HTAstFunction(this.funcStmt, HTAstInterpreter interpreter,
      {String? externalTypedef, List<HTTypeId> typeParams = const [], HTNamespace? context})
      : super(
          funcStmt.internalName,
          className: funcStmt.className,
          funcType: funcStmt.funcType,
          externalTypedef: externalTypedef,
          typeParams: typeParams,
          // typeid:
          isExtern: funcStmt.isExtern,
          isConst: funcStmt.isConst,
          isVariadic: funcStmt.isVariadic,
          minArity: funcStmt.arity,
        ) {
    this.interpreter = interpreter;
    this.context = context;

    var paramsTypes = <HTTypeId>[];
    for (final param in funcStmt.params) {
      paramsTypes.add(param.declType ?? HTTypeId.ANY);
    }
    typeid = HTFunctionTypeId(returnType: funcStmt.returnType, paramsTypes: paramsTypes);
  }

  @override
  String toString() {
    var result = StringBuffer();
    result.write('${HTLexicon.function}');
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
        result.write(HTLexicon.varargs + ' ');
      }
      result.write(param.id.lexeme + ': ' + (param.declType.toString()));
      //if (param.initializer != null)
      if (funcStmt.params.length > 1) result.write(', ');
    }
    result.write('): ' + funcStmt.returnType.toString());
    return result.toString();
  }

  @override
  dynamic call(
      [List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []]) {
    HTFunction.callStack.add(id);

    if (positionalArgs.length < funcStmt.arity ||
        (positionalArgs.length > funcStmt.params.length && !funcStmt.isVariadic)) {
      throw HTErrorArity(id, positionalArgs.length, funcStmt.arity);
    }

    dynamic result;
    try {
      if (funcStmt.definition != null) {
        // 函数每次在调用时，临时生成一个新的作用域
        final closure = HTNamespace(interpreter, closure: context);
        if (context is HTInstance) {
          closure.define(HTDeclaration(HTLexicon.THIS, value: context));
        }

        // TODO: 参数也改成Declaration而不是DeclStmt？
        for (var i = 0; i < funcStmt.params.length; ++i) {
          var param = funcStmt.params[i];

          if (funcStmt.params[i].isOptional &&
              (i >= positionalArgs.length) &&
              (funcStmt.params[i].initializer != null)) {
            positionalArgs.add(interpreter.visitASTNode(funcStmt.params[i].initializer!));
          } else if (funcStmt.params[i].isNamed &&
              (namedArgs[funcStmt.params[i].id.lexeme] == null) &&
              (funcStmt.params[i].initializer != null)) {
            namedArgs[funcStmt.params[i].id.lexeme] = interpreter.visitASTNode(funcStmt.params[i].initializer!);
          }

          var arg;
          if (!param.isNamed) {
            arg = positionalArgs[i];
          } else {
            arg = namedArgs[param.id.lexeme];
          }
          final arg_type_decl = param.declType ?? HTTypeId.ANY;

          if (!param.isVariadic) {
            var arg_type = interpreter.typeof(arg);
            if (arg_type.isNotA(arg_type_decl)) {
              throw HTErrorArgType(arg.toString(), arg_type.toString(), arg_type_decl.toString());
            }
            closure.define(HTDeclaration(param.id.lexeme, value: arg));
          } else {
            var varargs = [];
            for (var j = i; j < positionalArgs.length; ++j) {
              arg = positionalArgs[j];
              var arg_type = interpreter.typeof(arg);
              if (arg_type.isNotA(arg_type_decl)) {
                throw HTErrorArgType(arg.toString(), arg_type.toString(), arg_type_decl.toString());
              }
              varargs.add(arg);
            }
            closure.define(HTDeclaration(param.id.lexeme, value: varargs));
            break;
          }
        }

        result = interpreter.executeBlock(funcStmt.definition!, closure);
      } else {
        throw HTErrorMissingFuncDef(id);
      }
    } catch (returnValue) {
      if ((returnValue is HTError) || (returnValue is Exception) || (returnValue is Error)) {
        rethrow;
      }

      var returned_type = interpreter.typeof(returnValue);
      if (returned_type.isNotA(funcStmt.returnType)) {
        throw HTErrorReturnType(returned_type.toString(), id, funcStmt.returnType.toString());
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
}
