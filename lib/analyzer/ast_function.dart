import '../core/namespace/namespace.dart';
import '../core/declaration.dart';
import '../core/function/abstract_function.dart';
import '../core/object.dart';
import '../core/class/instance.dart';
import '../error/errors.dart';
import '../grammar/lexicon.dart';
import '../type_system/type.dart';
import 'ast/ast.dart';
import 'analyzer.dart';
import '../type_system/function_type.dart';

class HTAstFunction extends AbstractFunction {
  @override
  final HTAnalyzer interpreter;

  final FuncDecl funcStmt;

  HTAstFunction(this.funcStmt, this.interpreter, {HTNamespace? context})
      : super(funcStmt.id, interpreter,
            // klass: ,
            declId: funcStmt.declId,
            category: funcStmt.category,
            isExternal: false,
            externalId: funcStmt.externalTypedef,
            isStatic: funcStmt.isStatic,
            isConst: funcStmt.isConst,
            isVariadic: funcStmt.isVariadic,
            minArity: funcStmt.minArity,
            maxArity: funcStmt.maxArity,
            context: context) {
    valueType = HTFunctionType(
        parameterTypes:
            funcStmt.params.map((ast) => HTParameterType.fromAst(ast)).toList(),
        returnType: returnType);
  }

  @override
  String toString() {
    var result = StringBuffer();
    result.write('${HTLexicon.FUNCTION}');
    result.write(' $id');
    if (valueType.typeArgs.isNotEmpty) {
      result.write('<');
      for (var i = 0; i < valueType.typeArgs.length; ++i) {
        result.write(valueType.typeArgs[i]);
        if ((valueType.typeArgs.length > 1) &&
            (i != valueType.typeArgs.length - 1)) {
          result.write(', ');
        }
      }
      result.write('>');
    }

    result.write('(');

    for (final param in funcStmt.params) {
      if (param.isVariadic) {
        result.write(HTLexicon.variadicArgs + ' ');
      }
      result.write(param.id + ': ' + (param.declType.toString()));
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
      bool createInstance = true,
      bool errorHandled = true}) {
    AbstractFunction.callStack.add(id);

    if (positionalArgs.length < funcStmt.minArity ||
        (positionalArgs.length > funcStmt.params.length &&
            !funcStmt.isVariadic)) {
      throw HTError.arity(id, positionalArgs.length, funcStmt.minArity);
    }

    dynamic result;
    try {
      if (funcStmt.definition != null) {
        // 函数每次在调用时，临时生成一个新的作用域
        final closure = HTNamespace(interpreter, closure: context);
        if (context is HTInstance) {
          closure.define(
              HTDeclaration(HTLexicon.THIS, interpreter, value: context));
        }

        // TODO: 参数也改成Declaration而不是DeclStmt？
        // for (var i = 0; i < funcStmt.params.length; ++i) {
        //   var param = funcStmt.params[i];

        //   if (funcStmt.params[i].isOptional &&
        //       (i >= positionalArgs.length) &&
        //       (funcStmt.params[i].initializer != null)) {
        //     positionalArgs
        //         .add(interpreter.visitASTNode(funcStmt.params[i].initializer!));
        //   } else if (funcStmt.params[i].isNamed &&
        //       (namedArgs[funcStmt.params[i].id] == null) &&
        //       (funcStmt.params[i].initializer != null)) {
        //     namedArgs[funcStmt.params[i].id] =
        //         interpreter.visitASTNode(funcStmt.params[i].initializer!);
        //   }

        //   var arg;
        //   if (!param.isNamed) {
        //     arg = positionalArgs[i];
        //   } else {
        //     arg = namedArgs[param.id];
        //   }
        //   final argTypeid = param.declType ?? HTType.ANY;

        //   if (!param.isVariadic) {
        //     // final argEncapsulation = interpreter.encapsulate(arg);
        //     // if (argEncapsulation.valueType.isNotA(argTypeid)) {
        //     //   final arg_type = interpreter.encapsulate(arg).valueType;
        //     //   throw HTError.argType(
        //     //       arg.toString(), arg_type.toString(), argTypeid.toString());
        //     // }
        //     closure.define(HTVariable(param.id, interpreter, value: arg));
        //   } else {
        //     var varargs = [];
        //     for (var j = i; j < positionalArgs.length; ++j) {
        //       arg = positionalArgs[j];
        //       // final argEncapsulation = interpreter.encapsulate(arg);
        //       // if (argEncapsulation.valueType.isNotA(argTypeid)) {
        //       //   final arg_type = interpreter.encapsulate(arg).valueType;
        //       //   throw HTError.argType(
        //       //       arg.toString(), arg_type.toString(), argTypeid.toString());
        //       // }
        //       varargs.add(arg);
        //     }
        //     closure.define(HTVariable(param.id, interpreter, value: varargs));
        //     break;
        //   }
        // }

        // result =
        //     interpreter.executeBlock(funcStmt.definition!.statements, closure);
      } else {
        throw HTError.missingFuncBody(id);
      }
    } catch (returnValue) {
      if ((returnValue is HTError) ||
          (returnValue is Exception) ||
          (returnValue is Error)) {
        rethrow;
      }

      final encapsulation = interpreter.encapsulate(result);
      if (encapsulation.valueType.isNotA(returnType)) {
        throw HTError.returnType(
            encapsulation.valueType.toString(), id, returnType.toString());
      }

      if (returnValue is! NullThrownError && returnValue != HTObject.NULL) {
        result = returnValue;
      }

      AbstractFunction.callStack.removeLast();
      return result;
    }

    // 这里不能用finally，会导致异常无法继续抛出
    AbstractFunction.callStack.removeLast();
    return result;
  }
}
