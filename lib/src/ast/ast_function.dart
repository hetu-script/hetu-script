import '../class.dart';
import '../namespace.dart';
import '../errors.dart';
import '../type.dart';
import '../lexicon.dart';
import 'ast.dart';
import 'interpreter.dart';

import '../function.dart';

class HTAstFunction extends HTFunction with AstInterpreterRef {
  @override
  String get id => funcStmt.id?.lexeme ?? '';
  @override
  String get internalName => funcStmt.internalName;

  final FuncDeclStmt funcStmt;

  HTAstFunction(this.funcStmt, HTInterpreter interpreter, {HTNamespace? context, List<HTTypeId> typeArgs = const []}) {
    this.interpreter = interpreter;
    this.context = context;
    funcType = funcStmt.funcType;
    className = funcStmt.className;
    isExtern = funcStmt.isExtern;
    isStatic = funcStmt.isStatic;
    isConst = funcStmt.isConst;
    isVariadic = funcStmt.isVariadic;

    var paramsTypes = <HTTypeId?>[];
    for (final param in funcStmt.params) {
      paramsTypes.add(param.declType);
    }
    typeid = HTFunctionTypeId(funcStmt.returnType, arguments: typeArgs, paramsTypes: paramsTypes);
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
      {List<dynamic> positionalArgs = const [], Map<String, dynamic> namedArgs = const {}, HTInstance? instance}) {
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
        final callContext = instance ?? context!;
        if (callContext is HTInstance) {
          closure = HTNamespace(interpreter, id: '${callContext.id}.$id', closure: callContext);
          closure.define(HTLexicon.THIS, declType: callContext.typeid, isImmutable: true);
        } else {
          closure = HTNamespace(interpreter, id: '$id', closure: callContext);
        }

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
            closure.define(param.id.lexeme, declType: arg_type_decl, value: arg);
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
            closure.define(param.id.lexeme, declType: HTTypeId.list, value: varargs);
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

      if (returnValue is NullThrownError) return null;

      //_closure = _save;
      return returnValue;
    }

    HTFunction.callStack.removeLast();
    // 如果函数体中没有直接return，则会返回最后一个语句的值
    return result;
  }
}
