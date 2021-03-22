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
  @override
  String get id => funcStmt.id?.lexeme ?? '';
  @override
  String get internalName => funcStmt.internalName;

  final FuncDeclStmt funcStmt;

  HTAstFunction(this.funcStmt, HTAstInterpreter interpreter,
      {List<HTTypeId> typeParams = const [], HTNamespace? context})
      : super(
            id: funcStmt.id?.lexeme,
            className: funcStmt.className,
            funcType: funcStmt.funcType,
            typeParams: typeParams,
            // typeid:
            isExtern: funcStmt.isExtern,
            isConst: funcStmt.isConst,
            isVariadic: funcStmt.isVariadic,
            arity: funcStmt.arity) {
    this.interpreter = interpreter;

    var paramsTypes = <HTTypeId?>[];
    for (final param in funcStmt.params) {
      paramsTypes.add(param.declType);
    }
    typeid = HTFunctionTypeId(returnType: funcStmt.returnType, paramsTypes: paramsTypes);

    if (context != null) {
      this.context = context;
    }
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
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []}) {
    HTFunction.callStack.add(internalName);

    if (positionalArgs.length < funcStmt.arity ||
        (positionalArgs.length > funcStmt.params.length && !funcStmt.isVariadic)) {
      throw HTErrorArity(id, positionalArgs.length, funcStmt.arity);
    }

    dynamic result;
    try {
      if (funcStmt.definition != null) {
        HTNamespace closure;
        //_save = _closure;
        //assert(closure != null);
        // 函数每次在调用时，生成对应的作用域
        closure = HTNamespace(interpreter, closure: context);
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
            closure.define(HTDeclaration(param.id.lexeme, value: arg, declType: arg_type_decl));
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
            closure.define(HTDeclaration(param.id.lexeme, value: varargs, declType: HTTypeId.list));
            break;
          }
        }

        result = interpreter.executeBlock(funcStmt.definition!, closure);

        //_closure = _save;
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

      HTFunction.callStack.removeLast();

      if (returnValue is NullThrownError || returnValue == HTObject.NULL) return null;

      //_closure = _save;
      return returnValue;
    }

    HTFunction.callStack.removeLast();
    // 如果函数体中没有直接return，则会返回最后一个语句的值
    return result;
  }
}
