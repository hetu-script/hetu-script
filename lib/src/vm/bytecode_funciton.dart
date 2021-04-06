import 'vm.dart';
import 'bytecode_variable.dart';
import '../namespace.dart';
import '../type.dart';
import '../function.dart';
import '../common.dart';
import '../errors.dart';
import '../instance.dart';
import '../variable.dart';
import '../lexicon.dart';
import '../extern_function.dart';
import '../class.dart';

class HTBytecodeFunctionSuperConstructor {
  /// id of super class's constructor
  late final String id;

  /// Holds ips of super class's constructor's positional argumnets
  final List<int> positionalArgsIp;

  /// Holds ips of super class's constructor's named argumnets
  final Map<String, int> namedArgsIp;

  HTBytecodeFunctionSuperConstructor(String? id,
      {this.positionalArgsIp = const <int>[],
      this.namedArgsIp = const <String, int>{}}) {
    this.id =
        id == null ? HTLexicon.constructor : '${HTLexicon.constructor}$id';
  }
}

/// Bytecode implementation of [HTFunction].
class HTBytecodeFunction extends HTFunction with HetuRef {
  /// Holds declarations of all parameters.
  final Map<String, HTBytesParameter> parameterDeclarations;

  final HTBytecodeFunctionSuperConstructor? superConstructor;

  /// Holds ip of unction body.
  final int? definitionIp;

  /// Create a standard [HTBytecodeFunction].
  ///
  /// A [HTFunction] has to be defined in a [HTNamespace] of an [Interpreter]
  /// before it can be called within a script.
  HTBytecodeFunction(
    String id,
    Hetu interpreter,
    String moduleUniqueKey, {
    String declId = '',
    HTClass? klass,
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
    HTNamespace? context,
    this.superConstructor,
  }) : super(id, declId, moduleUniqueKey,
            klass: klass,
            funcType: funcType,
            externalFunctionType: externalFunctionType,
            externalTypedef: externalTypedef,
            typeParams: typeParams,
            isStatic: isStatic,
            isConst: isConst,
            isVariadic: isVariadic,
            minArity: minArity,
            maxArity: maxArity,
            context: context) {
    this.interpreter = interpreter;

    typeid = HTFunctionTypeId(
        returnType: returnType,
        paramsTypes: parameterDeclarations.values
            .map((paramDecl) => paramDecl.declType ?? HTTypeId.ANY)
            .toList());
  }

  /// Print function signature to String with function [id] and parameter [id].
  @override
  String toString() {
    var result = StringBuffer();
    result.write(HTLexicon.function);
    result.write(' $id');
    if (typeid.typeArguments.isNotEmpty) {
      result.write(HTLexicon.angleLeft);
      for (var i = 0; i < typeid.typeArguments.length; ++i) {
        result.write(typeid.typeArguments[i]);
        if ((typeid.typeArguments.length > 1) &&
            (i != typeid.typeArguments.length - 1)) {
          result.write(', ');
        }
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
      result.write(
          param.id + '${HTLexicon.colon} ' + (param.declType.toString()));
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
    result.write(
        '${HTLexicon.roundRight}${HTLexicon.colon} ' + returnType.toString());
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
      if (positionalArgs.length < minArity ||
          (positionalArgs.length > maxArity && !isVariadic)) {
        throw HTErrorArity(id, positionalArgs.length, minArity);
      }

      for (final name in namedArgs.keys) {
        if (!parameterDeclarations.containsKey(name)) {
          throw HTErrorNamedArg(name);
        }
      }

      var superCtorCalled = false;
      if (funcType == FunctionType.constructor && superConstructor != null) {
        final superClass = klass!.superClass!;
        final superCtorId = superConstructor!.id;
        final constructor =
            superClass.namespace.declarations[superCtorId] as HTFunction;
        // constructor's context is on this newly created instance
        final instanceNamespace = context as HTInstanceNamespace;
        constructor.context = instanceNamespace.next!;

        final superCtorPosArgs = [];
        final superCtorPosArgIps = superConstructor!.positionalArgsIp;
        for (var i = 0; i < superCtorPosArgIps.length; ++i) {
          final arg = interpreter.execute(ip: superCtorPosArgIps[i]);
          superCtorPosArgs.add(arg);
        }

        final superCtorNamedArgs = <String, dynamic>{};
        final superCtorNamedArgIps = superConstructor!.namedArgsIp;
        for (final name in superCtorNamedArgIps.keys) {
          final namedArgIp = superCtorNamedArgIps[name]!;
          final arg = interpreter.execute(ip: namedArgIp);
          superCtorNamedArgs[name] = arg;
        }

        constructor.call(
            positionalArgs: superCtorPosArgs, namedArgs: superCtorNamedArgs);

        superCtorCalled = true;
      }

      HTFunction.callStack.add(
          '#${HTFunction.callStack.length} $id - (${interpreter.curModuleUniqueKey}:${interpreter.curLine}:${interpreter.curColumn})');

      dynamic result;
      // 如果是脚本函数
      if (externalFunctionType == ExternalFunctionType.none) {
        if (definitionIp == null) {
          if (superCtorCalled) {
            return;
          }
          throw HTErrorMissingFuncDef(id);
        }
        // 函数每次在调用时，临时生成一个新的作用域
        final closure = HTNamespace(interpreter, id: id, closure: context);
        if (context is HTInstanceNamespace) {
          final instanceNamespace = context as HTInstanceNamespace;
          if (instanceNamespace.next != null) {
            closure.define(
                HTVariable(HTLexicon.SUPER, value: instanceNamespace.next));
          }

          closure.define(HTVariable(HTLexicon.THIS, value: instanceNamespace));
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

        result = interpreter.execute(
            moduleUniqueKey: moduleUniqueKey,
            ip: definitionIp!,
            namespace: closure);
      }
      // 如果是外部函数
      else {
        final finalPosArgs = <dynamic>[];
        final finalNamedArgs = <String, dynamic>{};

        var variadicStart = -1;
        HTBytecodeVariable? variadicParam;
        var i = 0;
        for (var param in parameterDeclarations.values) {
          var decl = param.clone();

          if (decl.isVariadic) {
            variadicStart = i;
            variadicParam = decl;
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

          finalNamedArgs[variadicParam!.id] = variadicArg;
        }

        // 单独绑定的外部函数
        if (externalFunctionType == ExternalFunctionType.externalFunction) {
          final externFunc = interpreter.fetchExternalFunction(id);
          if (externFunc is HTExternalFunction) {
            result = externFunc(
                positionalArgs: finalPosArgs,
                namedArgs: finalNamedArgs,
                typeArgs: typeArgs);
          } else {
            result = Function.apply(externFunc, finalPosArgs,
                namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
          }
        }
        // 整个外部类的成员函数
        else if (externalFunctionType ==
            ExternalFunctionType.externalClassMethod) {
          final externClass = interpreter.fetchExternalClass(classId!);

          final externFunc = externClass.memberGet(id);
          if (externFunc is HTExternalFunction) {
            result = externFunc(
                positionalArgs: finalPosArgs,
                namedArgs: finalNamedArgs,
                typeArgs: typeArgs);
          } else {
            result = Function.apply(externFunc, finalPosArgs,
                namedArgs.map((key, value) => MapEntry(Symbol(key), value)));
          }
        }
      }

      if (returnType != HTTypeId.ANY) {
        final encapsulation = interpreter.encapsulate(result);
        if (encapsulation.isNotA(returnType)) {
          throw HTErrorReturnType(
              encapsulation.typeid.toString(), id, returnType.toString());
        }
      }

      if (HTFunction.callStack.isNotEmpty) HTFunction.callStack.removeLast();
      return result;
    } catch (error, stack) {
      if (!errorHandled) rethrow;

      interpreter.handleError(error, stack);
    }
  }

  @override
  HTBytecodeFunction clone() {
    return HTBytecodeFunction(id, interpreter, moduleUniqueKey,
        declId: declId,
        klass: klass,
        funcType: funcType,
        externalFunctionType: externalFunctionType,
        externalTypedef: externalTypedef,
        parameterDeclarations: parameterDeclarations,
        returnType: returnType,
        definitionIp: definitionIp,
        typeParams: typeParams,
        isStatic: isStatic,
        isConst: isConst,
        isVariadic: isVariadic,
        minArity: minArity,
        maxArity: maxArity,
        context: context,
        superConstructor: superConstructor);
  }
}
