import '../namespace.dart';
import '../type.dart';
import 'vm.dart';
import '../function.dart';
import '../common.dart';
import 'bytes_declaration.dart';
import '../errors.dart';
import '../class.dart';
import '../declaration.dart';
import '../lexicon.dart';
import '../object.dart';

class HTBytesFunction extends HTFunction with VMRef {
  final Map<String, HTBytesParamDecl> paramDecls;

  final int? definitionIp;

  HTBytesFunction(String id, HTVM interpreter,
      {String? className,
      FunctionType funcType = FunctionType.normal,
      this.paramDecls = const <String, HTBytesParamDecl>{},
      HTTypeId? returnType,
      this.definitionIp,
      List<HTTypeId> typeParams = const [],
      bool isExtern = false,
      bool isStatic = false,
      bool isConst = false,
      bool isVariadic = false,
      int minArity = 0,
      int maxArity = 0,
      HTNamespace? context})
      : super(id,
            className: className,
            funcType: funcType,
            typeParams: typeParams,
            isExtern: isExtern,
            isStatic: isStatic,
            isConst: isConst,
            isVariadic: isVariadic,
            minArity: minArity,
            maxArity: maxArity) {
    this.interpreter = interpreter;
    this.context = context;

    typeid = HTFunctionTypeId(
        returnType: returnType ?? HTTypeId.ANY,
        paramsTypes: paramDecls.values.map((paramDecl) => paramDecl.declType ?? HTTypeId.ANY).toList());
  }

  // @override
  // String toString() {
  // var result = StringBuffer();
  // result.write('${HTLexicon.function}');
  // result.write(' $id');
  // if (typeid.arguments.isNotEmpty) {
  //   result.write('<');
  //   for (var i = 0; i < typeid.arguments.length; ++i) {
  //     result.write(typeid.arguments[i]);
  //     if ((typeid.arguments.length > 1) && (i != typeid.arguments.length - 1)) result.write(', ');
  //   }
  //   result.write('>');
  // }

  // result.write('(');

  // for (final param in funcStmt.params) {
  //   if (param.isVariadic) {
  //     result.write(HTLexicon.varargs + ' ');
  //   }
  //   result.write(param.id.lexeme + ': ' + (param.declType.toString()));
  //   //if (param.initializer != null)
  //   if (funcStmt.params.length > 1) result.write(', ');
  // }
  // result.write('): ' + funcStmt.returnType.toString());
  // return result.toString();
  // }

  @override
  dynamic call(
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []}) {
    HTFunction.callStack.add(id);

    if (definitionIp == null) {
      throw HTErrorMissingFuncDef(id);
    }

    if (positionalArgs.length < minArity || (positionalArgs.length > maxArity && !isVariadic)) {
      throw HTErrorArity(id, positionalArgs.length, minArity);
    }

    for (final name in namedArgs.keys) {
      if (!paramDecls.containsKey(name)) {
        throw HTErrorNamedArg(name);
      }
    }

    dynamic result;
    try {
      // 函数每次在调用时，临时生成一个新的作用域
      final closure = HTNamespace(interpreter, closure: context);
      if (context is HTInstance) {
        closure.define(HTDeclaration(HTLexicon.THIS, value: context));
      }

      var variadicStart = -1;
      HTBytesDecl? variadicParam;
      for (var i = 0; i < paramDecls.length; ++i) {
        var decl = paramDecls.values.elementAt(i).clone();
        closure.define(decl);

        if (i < positionalArgs.length) {
          if (!decl.isVariadic) {
            decl.assign(positionalArgs[i]);
          } else {
            variadicStart = i;
            variadicParam = decl;
            break;
          }
        } else if (i < maxArity) {
          decl.initialize();
        } else {
          if (namedArgs.containsKey(decl.id)) {
            decl.assign(namedArgs[decl.id]);
          } else {
            decl.initialize();
          }
        }
      }

      if (variadicStart >= 0) {
        final variadicArg = <dynamic>[];
        for (var i = variadicStart; i < positionalArgs.length; ++i) {
          variadicArg.add(positionalArgs[i]);
        }
        variadicParam!.assign(variadicArg);
      }

      result = interpreter.execute(ip: definitionIp!, closure: closure);
    } catch (returnValue) {
      if ((returnValue is HTError) || (returnValue is Exception) || (returnValue is Error)) {
        rethrow;
      }

      var returned_type = interpreter.typeof(returnValue);
      if (returned_type.isNotA(returnType)) {
        throw HTErrorReturnType(returned_type.toString(), id, returnType.toString());
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
