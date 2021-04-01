import 'package:hetu_script/src/extern_function.dart';

import 'vm.dart';
import 'bytes_variable.dart';
import '../namespace.dart';
import '../type.dart';
import '../function.dart';
import '../common.dart';
import '../errors.dart';
import '../class.dart';
import '../variable.dart';
import '../lexicon.dart';

class HTBytesFunction extends HTFunction with HetuRef {
  final Map<String, HTBytesParameter> paramDecls;

  final int? definitionIp;

  HTBytesFunction(String id, Hetu interpreter, String module,
      {String declId = '',
      String? classId,
      FunctionType funcType = FunctionType.normal,
      ExternalFuncDeclType externType = ExternalFuncDeclType.none,
      String? externalTypedef,
      this.paramDecls = const <String, HTBytesParameter>{},
      HTTypeId? returnType,
      this.definitionIp,
      List<HTTypeId> typeParams = const [],
      bool isStatic = false,
      bool isConst = false,
      bool isVariadic = false,
      int minArity = 0,
      int maxArity = 0,
      HTNamespace? context})
      : super(id, declId, module,
            classId: classId,
            funcType: funcType,
            externalFuncDeclType: externType,
            externalTypedef: externalTypedef,
            typeParams: typeParams,
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

    var i = 0;
    for (final param in paramDecls.values) {
      if (param.isVariadic) {
        result.write(HTLexicon.varargs + ' ');
      }
      result.write(param.id + ': ' + (param.declType.toString()));
      //if (param.initializer != null)
      //TODO: optional and named params;
      ++i;
      if (i < paramDecls.length - 1) result.write(', ');
    }
    result.write('): ' + returnType.toString());
    return result.toString();
  }

  @override
  dynamic call(
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const []}) {
    if (positionalArgs.length < minArity || (positionalArgs.length > maxArity && !isVariadic)) {
      throw HTErrorArity(id, positionalArgs.length, minArity);
    }

    for (final name in namedArgs.keys) {
      if (!paramDecls.containsKey(name)) {
        throw HTErrorNamedArg(name);
      }
    }

    HTFunction.callStack.add(
        '#${HTFunction.callStack.length} $id - (${interpreter.curModuleName}:${interpreter.curLine}:${interpreter.curColumn})');

    dynamic result;
    // 如果是脚本函数
    if (externalFuncDeclType == ExternalFuncDeclType.none) {
      if (definitionIp == null) {
        throw HTErrorMissingFuncDef(id);
      }
      // 函数每次在调用时，临时生成一个新的作用域
      final closure = HTNamespace(interpreter, id: id, closure: context);
      if (context is HTInstance) {
        closure.define(HTVariable(HTLexicon.THIS, value: context));
      }

      var variadicStart = -1;
      HTBytesVariable? variadicParam;
      for (var i = 0; i < paramDecls.length; ++i) {
        var decl = paramDecls.values.elementAt(i).clone();
        closure.define(decl);

        if (decl.isVariadic) {
          variadicStart = i;
          variadicParam = decl;
          break;
        } else {
          if (i < maxArity) {
            if (i < positionalArgs.length) {
              decl.assign(positionalArgs[i]);
            } else {
              decl.initialize();
            }
          } else {
            if (namedArgs.containsKey(decl.id)) {
              decl.assign(namedArgs[decl.id]);
            } else {
              decl.initialize();
            }
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

      result = interpreter.execute(moduleName: module, ip: definitionIp!, namespace: closure);
    }
    // 如果是外部函数
    else {
      final finalPosArgs = <dynamic>[];
      final finalNamedArgs = <String, dynamic>{};

      var variadicStart = -1;
      var i = 0;
      for (var param in paramDecls.values) {
        var decl = param.clone();

        if (decl.isVariadic) {
          variadicStart = i;
          break;
        } else {
          if (i < maxArity) {
            if (i < positionalArgs.length) {
              finalPosArgs.add(positionalArgs[i]);
            } else {
              decl.initialize();
              finalPosArgs.add(decl.value);
            }
          } else {
            if (namedArgs.containsKey(decl.id)) {
              finalNamedArgs[decl.id] = namedArgs[decl.id];
            } else {
              decl.initialize();
              finalNamedArgs[decl.id] = decl.value;
            }
          }
        }

        ++i;
      }

      if (variadicStart >= 0) {
        final variadicArg = <dynamic>[];
        for (var i = variadicStart; i < positionalArgs.length; ++i) {
          variadicArg.add(positionalArgs[i]);
        }

        finalPosArgs.add(variadicArg);
      }

      // 单独绑定的外部函数
      if (externalFuncDeclType == ExternalFuncDeclType.standalone) {
        final externFunc = interpreter.fetchExternalFunction(id);
        if (externFunc is HTExternalFunction) {
          result = externFunc(positionalArgs: finalPosArgs, namedArgs: finalNamedArgs, typeArgs: typeArgs);
        } else {
          result =
              Function.apply(externFunc, finalPosArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
        }
      }
      // 整个外部类的成员函数
      else if (externalFuncDeclType == ExternalFuncDeclType.klass) {
        final externClass = interpreter.fetchExternalClass(classId!);

        final externFunc = externClass.memberGet(id);
        if (externFunc is HTExternalFunction) {
          result = externFunc(positionalArgs: finalPosArgs, namedArgs: finalNamedArgs, typeArgs: typeArgs);
        } else {
          result =
              Function.apply(externFunc, finalPosArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
        }
      }
    }

    final encapsulation = interpreter.encapsulate(result);
    if (encapsulation.isNotA(returnType)) {
      throw HTErrorReturnType(encapsulation.typeid.toString(), id, returnType.toString());
    }

    if (HTFunction.callStack.isNotEmpty) HTFunction.callStack.removeLast();
    return result;
  }
}
