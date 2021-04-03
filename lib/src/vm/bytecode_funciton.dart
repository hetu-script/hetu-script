import 'package:hetu_script/src/extern_function.dart';

import 'vm.dart';
import 'bytecode_variable.dart';
import '../namespace.dart';
import '../type.dart';
import '../function.dart';
import '../common.dart';
import '../errors.dart';
import '../class.dart';
import '../variable.dart';
import '../lexicon.dart';

/// Bytecode implementation of [HTFunction].
class HTBytecodeFunction extends HTFunction with HetuRef {
  /// Holds declarations of all parameters.
  final Map<String, HTBytesParameter> parameterDeclarations;

  /// intruction pointer of the function body.
  final int? definitionIp;

  /// Create a standard [HTBytecodeFunction].
  ///
  /// A [HTFunction] has to be defined in a [HTNamespace] of an [Interpreter]
  /// before it can be called within a script.
  HTBytecodeFunction(String id, Hetu interpreter, String module,
      {String declId = '',
      String? classId,
      FunctionType funcType = FunctionType.normal,
      ExternalFunctionType externalFunctionType = ExternalFunctionType.none,
      String? externalTypedef,
      this.parameterDeclarations = const <String, HTBytesParameter>{},
      HTTypeId returnType = HTTypeId.ANY,
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
            externalFunctionType: externalFunctionType,
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
        returnType: returnType,
        paramsTypes: parameterDeclarations.values.map((paramDecl) => paramDecl.declType ?? HTTypeId.ANY).toList());
  }

  /// Print function signature to String with function [id] and parameter [id].
  @override
  String toString() {
    var result = StringBuffer();
    result.write(HTLexicon.function);
    result.write(' $id');
    if (typeid.arguments.isNotEmpty) {
      result.write(HTLexicon.angleLeft);
      for (var i = 0; i < typeid.arguments.length; ++i) {
        result.write(typeid.arguments[i]);
        if ((typeid.arguments.length > 1) && (i != typeid.arguments.length - 1)) result.write(', ');
      }
      result.write(HTLexicon.angleRight);
    }

    result.write(HTLexicon.roundLeft);

    var i = 0;
    var optionalStarted = false;
    var namedStarted = false;
    for (final param in parameterDeclarations.values) {
      if (param.isVariadic) {
        result.write(HTLexicon.varargs + ' ');
      }
      if (param.isOptional && !optionalStarted) {
        optionalStarted = true;
        result.write(HTLexicon.squareLeft);
      } else if (param.isNamed && !namedStarted) {
        namedStarted = true;
        result.write(HTLexicon.curlyLeft);
      }
      result.write(param.id + '${HTLexicon.colon} ' + (param.declType.toString()));
      //if (param.initializer != null)
      //TODO: optional and named params;
      if (i < parameterDeclarations.length - 1) {
        result.write('${HTLexicon.comma} ');
      }
      if (optionalStarted) {
        result.write(HTLexicon.squareRight);
      } else if (namedStarted) {
        namedStarted = true;
        result.write(HTLexicon.curlyRight);
      }
      ++i;
    }
    result.write('${HTLexicon.roundRight}${HTLexicon.colon} ' + returnType.toString());
    return result.toString();
  }

  /// Call this function with specific arguments.
  /// ```
  /// function<typeArg1, typeArg2>(posArg1, posArg2, name1: namedArg1, name2: namedArg2)
  /// ```
  /// for variadic arguments, will transform all remaining positional arguments
  /// into a named argument with the variadic argument's name.
  /// variadic declaration:
  /// ```
  /// fun function(... args)
  /// ```
  /// variadic calling:
  /// ```
  /// function(posArg1, posArg2...)
  /// ```
  /// [HTBytecodeFunction.call]:
  /// ```
  /// namedArgs['args'] = [posArg1, posArg2...];
  /// ```
  @override
  dynamic call(
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const [],
      bool errorHandled = true}) {
    try {
      if (positionalArgs.length < minArity || (positionalArgs.length > maxArity && !isVariadic)) {
        throw HTErrorArity(id, positionalArgs.length, minArity);
      }

      for (final name in namedArgs.keys) {
        if (!parameterDeclarations.containsKey(name)) {
          throw HTErrorNamedArg(name);
        }
      }

      HTFunction.callStack.add(
          '#${HTFunction.callStack.length} $id - (${interpreter.curModuleUniqueKey}:${interpreter.curLine}:${interpreter.curColumn})');

      dynamic result;
      // 如果是脚本函数
      if (externalFunctionType == ExternalFunctionType.none) {
        if (definitionIp == null) {
          throw HTErrorMissingFuncDef(id);
        }
        // 函数每次在调用时，临时生成一个新的作用域
        final closure = HTNamespace(interpreter, id: id, closure: context);
        if (context is HTInstance) {
          closure.define(HTVariable(HTLexicon.THIS, value: context));
        }

        var variadicStart = -1;
        HTBytecodeVariable? variadicParam;
        for (var i = 0; i < parameterDeclarations.length; ++i) {
          var decl = parameterDeclarations.values.elementAt(i).clone();
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

        result = interpreter.execute(moduleUniqueKey: moduleUniqueKey, ip: definitionIp!, namespace: closure);
      }
      // 如果是外部函数
      else {
        final finalPosArgs = <dynamic>[];
        final finalNamedArgs = <String, dynamic>{};

        var variadicStart = -1;
        var i = 0;
        for (var param in parameterDeclarations.values) {
          var decl = param.clone();

          if (decl.isVariadic) {
            variadicStart = i;
            break;
          } else {
            if (i < maxArity) {
              if (i < positionalArgs.length) {
                decl.assign(positionalArgs[i]);
                finalPosArgs.add(decl.value);
              } else {
                decl.initialize();
                finalPosArgs.add(decl.value);
              }
            } else {
              if (namedArgs.containsKey(decl.id)) {
                decl.assign(namedArgs[decl.id]);
                finalNamedArgs[decl.id] = decl.value;
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
        if (externalFunctionType == ExternalFunctionType.externalFunction) {
          final externFunc = interpreter.fetchExternalFunction(id);
          if (externFunc is HTExternalFunction) {
            result = externFunc(positionalArgs: finalPosArgs, namedArgs: finalNamedArgs, typeArgs: typeArgs);
          } else {
            result =
                Function.apply(externFunc, finalPosArgs, namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
          }
        }
        // 整个外部类的成员函数
        else if (externalFunctionType == ExternalFunctionType.externalClassMethod) {
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
    } catch (error, stack) {
      if (!errorHandled) rethrow;

      interpreter.handleError(error, stack);
    }
  }
}
