import 'vm.dart';
import 'bytecode_variable.dart';
import 'bytecode.dart' show GotoInfo;
import '../namespace.dart';
import '../type.dart';
import '../function.dart';
import '../common.dart';
import '../errors.dart';
import '../variable.dart';
import '../lexicon.dart';
import '../binding/external_function.dart';
import '../class.dart';
import '../instance.dart';

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
class HTBytecodeFunction extends HTFunction with GotoInfo, HetuRef {
  final bool hasParameterDeclarations;

  /// Holds declarations of all parameters.
  final Map<String, HTBytecodeParameter> parameterDeclarations;

  final HTBytecodeFunctionSuperConstructor? superConstructor;

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
    bool isExtern = false,
    String? externalTypedef,
    this.hasParameterDeclarations = true,
    this.parameterDeclarations = const <String, HTBytecodeParameter>{},
    HTType returnType = HTType.ANY,
    int? definitionIp,
    int? definitionLine,
    int? definitionColumn,
    bool isStatic = false,
    bool isConst = false,
    bool isVariadic = false,
    int minArity = 0,
    int maxArity = 0,
    HTNamespace? context,
    this.superConstructor,
  }) : super(id, declId,
            klass: klass,
            funcType: funcType,
            isExtern: isExtern,
            externalTypedef: externalTypedef,
            isStatic: isStatic,
            isConst: isConst,
            isVariadic: isVariadic,
            minArity: minArity,
            maxArity: maxArity,
            context: context) {
    this.interpreter = interpreter;
    this.moduleUniqueKey = moduleUniqueKey;
    this.definitionIp = definitionIp;
    this.definitionLine = definitionLine;
    this.definitionColumn = definitionColumn;

    rtType = HTFunctionType(
        parameterTypes: parameterDeclarations
            .map((key, value) => MapEntry(key, value.paramType)),
        minArity: minArity,
        returnType: returnType);
  }

  /// Print function signature to String with function [id] and parameter [id].
  @override
  String toString() {
    var result = StringBuffer();
    result.write(HTLexicon.FUNCTION);
    result.write(' $id');
    if (rtType.typeArgs.isNotEmpty) {
      result.write(HTLexicon.angleLeft);
      for (var i = 0; i < rtType.typeArgs.length; ++i) {
        result.write(rtType.typeArgs[i]);
        if (i < rtType.typeArgs.length - 1) {
          result.write('${HTLexicon.comma} ');
        }
      }
      result.write(HTLexicon.angleRight);
    }

    result.write(HTLexicon.roundLeft);

    var i = 0;
    var optionalStarted = false;
    var namedStarted = false;
    for (final param in parameterDeclarations.values) {
      if (param.paramType.isVariadic) {
        result.write(HTLexicon.varargs + ' ');
      }
      if (param.paramType.isOptional && !optionalStarted) {
        optionalStarted = true;
        result.write(HTLexicon.squareLeft);
      } else if (param.paramType.isNamed && !namedStarted) {
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
        '${HTLexicon.roundRight}${HTLexicon.arrow} ' + returnType.toString());
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
      List<HTType> typeArgs = const [],
      bool createInstance = true,
      bool errorHandled = true}) {
    try {
      HTFunction.callStack.add(
          '#${HTFunction.callStack.length} $id - (${interpreter.curModuleUniqueKey}:${interpreter.curLine}:${interpreter.curColumn})');

      dynamic result;
      // 如果是脚本函数
      if (!isExtern) {
        if (positionalArgs.length < minArity ||
            (positionalArgs.length > maxArity && !isVariadic)) {
          throw HTError.arity(id, positionalArgs.length, minArity);
        }

        for (final name in namedArgs.keys) {
          if (!parameterDeclarations.containsKey(name)) {
            throw HTError.namedArg(name);
          }
        }

        if (funcType == FunctionType.constructor && createInstance) {
          result = HTInstance(klass!, interpreter, typeArgs: typeArgs);
          context = result.namespace;
        }

        if (definitionIp == null) {
          return result;
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
              positionalArgs: superCtorPosArgs,
              namedArgs: superCtorNamedArgs,
              createInstance: false);
        }

        var variadicStart = -1;
        HTBytecodeVariable? variadicParam;
        for (var i = 0; i < parameterDeclarations.length; ++i) {
          var decl = parameterDeclarations.values.elementAt(i).clone();
          closure.define(decl);

          if (decl.paramType.isVariadic) {
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

        if (funcType != FunctionType.constructor) {
          result = interpreter.execute(
              moduleUniqueKey: moduleUniqueKey,
              ip: definitionIp!,
              namespace: closure,
              line: definitionLine,
              column: definitionColumn);
        } else {
          interpreter.execute(
              moduleUniqueKey: moduleUniqueKey,
              ip: definitionIp!,
              namespace: closure,
              line: definitionLine,
              column: definitionColumn);
        }
      }
      // 如果是外部函数
      else {
        late final finalPosArgs;
        late final finalNamedArgs;

        if (hasParameterDeclarations) {
          if (positionalArgs.length < minArity ||
              (positionalArgs.length > maxArity && !isVariadic)) {
            throw HTError.arity(id, positionalArgs.length, minArity);
          }

          for (final name in namedArgs.keys) {
            if (!parameterDeclarations.containsKey(name)) {
              throw HTError.namedArg(name);
            }
          }

          finalPosArgs = <dynamic>[];
          finalNamedArgs = <String, dynamic>{};

          var variadicStart = -1;
          HTBytecodeVariable? variadicParam;
          var i = 0;
          for (var param in parameterDeclarations.values) {
            var decl = param.clone();

            if (decl.paramType.isVariadic) {
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
        } else {
          finalPosArgs = positionalArgs;
          finalNamedArgs = namedArgs;
        }

        // 单独绑定的外部函数
        if (!(klass?.isExtern ?? false)) {
          // 普通外部函数或者内部类的外部成员函数
          late final externFunc = interpreter.fetchExternalFunction(id);
          if (externFunc is HTExternalFunction) {
            result = externFunc(
                positionalArgs: finalPosArgs,
                namedArgs: finalNamedArgs,
                typeArgs: typeArgs);
          } else {
            result = Function.apply(
                externFunc,
                finalPosArgs,
                finalNamedArgs
                    .map((key, value) => MapEntry(Symbol(key), value)));
          }
        }
        // 外部类的成员函数
        else {
          final externClass = interpreter.fetchExternalClass(classId!);

          // final typeArgsString = convertTypeArgsToString(typeArgs);
          // final externFunc = externClass.memberGet('$id$typeArgsString');

          final externFunc = externClass.memberGet(id);
          if (externFunc is HTExternalFunction) {
            result = externFunc(
                positionalArgs: finalPosArgs,
                namedArgs: finalNamedArgs,
                typeArgs: typeArgs);
          } else {
            // Use Function.apply will lose type args information.
            result = Function.apply(
                externFunc,
                finalPosArgs,
                finalNamedArgs
                    .map((key, value) => MapEntry(Symbol(key), value)));
          }
        }
      }

      if (funcType != FunctionType.constructor) {
        if (returnType != HTType.ANY) {
          final encapsulation = interpreter.encapsulate(result);
          if (encapsulation.rtType.isNotA(returnType)) {
            throw HTError.returnType(
                encapsulation.rtType.toString(), id, returnType.toString());
          }
        }
      }

      if (HTFunction.callStack.isNotEmpty) {
        HTFunction.callStack.removeLast();
      }

      return result;
    } catch (error, stack) {
      if (errorHandled) {
        rethrow;
      } else {
        interpreter.handleError(error, stack);
      }
    }
  }

  @override
  HTBytecodeFunction clone() {
    return HTBytecodeFunction(id, interpreter, moduleUniqueKey,
        declId: declId,
        klass: klass,
        funcType: funcType,
        isExtern: isExtern,
        externalTypedef: externalTypedef,
        parameterDeclarations: parameterDeclarations,
        returnType: returnType,
        definitionIp: definitionIp,
        definitionLine: definitionLine,
        definitionColumn: definitionColumn,
        isStatic: isStatic,
        isConst: isConst,
        isVariadic: isVariadic,
        minArity: minArity,
        maxArity: maxArity,
        context: context,
        superConstructor: superConstructor);
  }
}
