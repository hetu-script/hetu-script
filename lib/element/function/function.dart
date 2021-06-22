import '../../binding/external_function.dart';
import '../../error/error.dart';
import '../../grammar/semantic.dart';
import '../../grammar/lexicon.dart';
import 'typed_function_declaration.dart';
import '../../interpreter/interpreter.dart';
import '../../interpreter/compiler.dart' show GotoInfo;
import '../../type/type.dart';
import '../instance/instance_namespace.dart';
import '../class/class.dart';
import '../instance/instance.dart';
import '../object.dart';
import '../variable/variable.dart';
import '../namespace.dart';
import 'parameter.dart';

class ReferConstructor {
  /// id of super class's constructor
  // final String callee;
  final bool isSuper;

  final String? name;

  /// Holds ips of super class's constructor's positional argumnets
  final List<int> positionalArgsIp;

  /// Holds ips of super class's constructor's named argumnets
  final Map<String, int> namedArgsIp;

  ReferConstructor(
      {this.isSuper = false,
      this.name,
      this.positionalArgsIp = const [],
      this.namedArgsIp = const {}});
}

/// Bytecode implementation of [TypedFunctionDeclaration].
class HTFunction extends HTTypedFunctionDeclaration
    with HTObject, HetuRef, GotoInfo {
  static final callStack = <String>[];

  HTClass? klass;

  /// Wether to check params when called
  /// A function like:
  ///   ```
  ///     fun { return 42 }
  ///   ```
  /// will accept any params, while a function:
  ///   ```
  ///     fun () { return 42 }
  ///   ```
  /// will accept 0 params
  final bool hasParamDecls;

  /// Holds declarations of all parameters.
  final Map<String, HTParameter> paramDecls;

  final ReferConstructor? referConstructor;

  HTNamespace? context;

  @override
  HTType get valueType => HTType.function;

  /// Create a standard [HTFunction].
  ///
  /// A [TypedFunctionDeclaration] has to be defined in a [HTNamespace] of an [Interpreter]
  /// before it can be called within a script.
  HTFunction(
      String id, String moduleFullName, String libraryName, Hetu interpreter,
      {String declId = '',
      String? classId,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      int? definitionIp,
      int? definitionLine,
      int? definitionColumn,
      FunctionCategory category = FunctionCategory.normal,
      Function? externalFunc,
      String? externalTypeId,
      bool isVariadic = false,
      this.hasParamDecls = true,
      this.paramDecls = const <String, HTParameter>{},
      int minArity = 0,
      int maxArity = 0,
      HTNamespace? closure,
      this.context,
      this.referConstructor,
      this.klass})
      : super(id, moduleFullName, libraryName,
            declId: declId,
            classId: classId,
            isExternal: isExternal,
            isStatic: isStatic,
            isConst: isConst,
            category: category,
            externalFunc: externalFunc,
            externalTypeId: externalTypeId,
            isVariadic: isVariadic,
            minArity: minArity,
            maxArity: maxArity,
            closure: closure) {
    this.interpreter = interpreter;
    this.definitionIp = definitionIp;
    this.definitionLine = definitionLine;
    this.definitionColumn = definitionColumn;
  }

  @override
  dynamic get value {
    if (externalTypeId != null) {
      final externalFunc = interpreter.unwrapExternalFunctionType(this);
      return externalFunc;
    } else {
      return this;
    }
  }

  @override
  void resolve() {
    super.resolve();

    if ((closure != null) && (classId != null) && (klass == null)) {
      klass = closure!.memberGet(classId!, from: closure!.fullName);
    }
  }

  @override
  HTFunction clone() => HTFunction(id, moduleFullName, libraryName, interpreter,
      declId: declId,
      classId: classId,
      isExternal: isExternal,
      isStatic: isStatic,
      isConst: isConst,
      definitionIp: definitionIp,
      definitionLine: definitionLine,
      definitionColumn: definitionColumn,
      category: category,
      externalFunc: externalFunc,
      externalTypeId: externalTypeId,
      isVariadic: isVariadic,
      hasParamDecls: hasParamDecls,
      paramDecls: paramDecls,
      minArity: minArity,
      maxArity: maxArity,
      closure: closure,
      context: context,
      referConstructor: referConstructor,
      klass: klass);

  /// Call this function with specific arguments.
  /// ```
  /// function<typeArg1, typeArg2>(posArg1, posArg2, name1: namedArg1, name2: namedArg2)
  /// ```
  /// for variadic arguments, will transform all remaining positional arguments
  /// into a positional argument with the variadic argument's name.
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
  dynamic call(
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool createInstance = true,
      bool errorHandled = true}) {
    try {
      callStack.add(
          '#${callStack.length} $id - (${interpreter.curModuleFullName}:${interpreter.curLine}:${interpreter.curColumn})');

      dynamic result;
      // 如果是脚本函数
      if (!isExternal) {
        if (positionalArgs.length < minArity ||
            (positionalArgs.length > maxArity && !isVariadic)) {
          throw HTError.arity(id, positionalArgs.length, minArity);
        }

        for (final name in namedArgs.keys) {
          if (!paramDecls.containsKey(name)) {
            throw HTError.namedArg(name);
          }
        }

        if (category == FunctionCategory.constructor && createInstance) {
          result = HTInstance(klass!, interpreter, typeArgs: typeArgs);
          context = result.namespace;
        }

        if (definitionIp == null) {
          return result;
        }
        // 函数每次在调用时，临时生成一个新的作用域
        final callClosure =
            HTNamespace(moduleFullName, libraryName, id: id, closure: context);
        if (context is HTInstanceNamespace) {
          final instanceNamespace = context as HTInstanceNamespace;
          if (instanceNamespace.next != null) {
            callClosure.define(
                HTLexicon.SUPER,
                HTVariable(
                    HTLexicon.SUPER, moduleFullName, libraryName, interpreter,
                    value: instanceNamespace.next));
          }

          callClosure.define(
              HTLexicon.THIS,
              HTVariable(
                  HTLexicon.THIS, moduleFullName, libraryName, interpreter,
                  value: instanceNamespace));
        }

        if (category == FunctionCategory.constructor &&
            referConstructor != null) {
          late final HTFunction constructor;
          final name = referConstructor!.name;
          if (referConstructor!.isSuper) {
            final superClass = klass!.superClass!;
            if (name == null) {
              constructor = superClass
                  .namespace.declarations[SemanticNames.constructor]!.value;
            } else {
              constructor = superClass.namespace
                  .declarations['${SemanticNames.constructor}$name']!.value;
            }
          }
          // (callee == HTLexicon.THIS)
          else {
            if (name == null) {
              constructor = klass!
                  .namespace.declarations[SemanticNames.constructor]!.value;
            } else {
              constructor = klass!.namespace
                  .declarations['${SemanticNames.constructor}$name']!.value;
            }
          }

          // constructor's context is on this newly created instance
          final instanceNamespace = context as HTInstanceNamespace;
          constructor.context = instanceNamespace.next!;

          final referCtorPosArgs = [];
          final referCtorPosArgIps = referConstructor!.positionalArgsIp;
          for (var i = 0; i < referCtorPosArgIps.length; ++i) {
            final arg = interpreter.execute(
                moduleFullName: moduleFullName,
                libraryName: libraryName,
                ip: referCtorPosArgIps[i],
                namespace: callClosure);
            referCtorPosArgs.add(arg);
          }

          final referCtorNamedArgs = <String, dynamic>{};
          final referCtorNamedArgIps = referConstructor!.namedArgsIp;
          for (final name in referCtorNamedArgIps.keys) {
            final referCtorNamedArgIp = referCtorNamedArgIps[name]!;
            final arg = interpreter.execute(
                moduleFullName: moduleFullName,
                libraryName: libraryName,
                ip: referCtorNamedArgIp,
                namespace: callClosure);
            referCtorNamedArgs[name] = arg;
          }

          constructor.call(
              positionalArgs: referCtorPosArgs,
              namedArgs: referCtorNamedArgs,
              createInstance: false);
        }

        var variadicStart = -1;
        HTVariable? variadicParam;
        for (var i = 0; i < paramDecls.length; ++i) {
          var decl = paramDecls.values.elementAt(i).clone();
          callClosure.define(decl.id, decl);

          if (decl.isVariadic) {
            variadicStart = i;
            variadicParam = decl;
            break;
          } else {
            if (i < maxArity) {
              if (i < positionalArgs.length) {
                decl.value = positionalArgs[i];
              } else {
                decl.initialize();
              }
            } else {
              if (namedArgs.containsKey(decl.id)) {
                decl.value = namedArgs[decl.id];
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
          variadicParam!.value = variadicArg;
        }

        if (category != FunctionCategory.constructor) {
          result = interpreter.execute(
              moduleFullName: moduleFullName,
              libraryName: libraryName,
              ip: definitionIp,
              namespace: callClosure,
              function: this,
              line: definitionLine,
              column: definitionColumn);
        } else {
          interpreter.execute(
              moduleFullName: moduleFullName,
              libraryName: libraryName,
              ip: definitionIp,
              namespace: callClosure,
              function: this,
              line: definitionLine,
              column: definitionColumn);
        }
      }
      // 如果是外部函数
      else {
        late final List<dynamic> finalPosArgs;
        late final Map<String, dynamic> finalNamedArgs;

        if (hasParamDecls) {
          if (positionalArgs.length < minArity ||
              (positionalArgs.length > maxArity && !isVariadic)) {
            throw HTError.arity(id, positionalArgs.length, minArity);
          }

          for (final name in namedArgs.keys) {
            if (!paramDecls.containsKey(name)) {
              throw HTError.namedArg(name);
            }
          }

          finalPosArgs = [];
          finalNamedArgs = {};

          var variadicStart = -1;
          // HTBytecodeVariable? variadicParam;
          var i = 0;
          for (var param in paramDecls.values) {
            var decl = param.clone();

            if (decl.isVariadic) {
              variadicStart = i;
              // variadicParam = decl;
              break;
            } else {
              if (i < maxArity) {
                if (i < positionalArgs.length) {
                  decl.value = positionalArgs[i];
                  finalPosArgs.add(decl.value);
                } else {
                  decl.initialize();
                  finalPosArgs.add(decl.value);
                }
              } else {
                if (namedArgs.containsKey(decl.id)) {
                  decl.value = namedArgs[decl.id];
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
        } else {
          finalPosArgs = positionalArgs;
          finalNamedArgs = namedArgs;
        }

        // standalone binding external function
        // either a normal external function or
        // a external static method in a non-external class
        if (!(klass?.isExternal ?? false)) {
          externalFunc ??= interpreter.fetchExternalFunction(id);

          if (externalFunc is HTExternalFunction) {
            result = externalFunc!(
                positionalArgs: finalPosArgs,
                namedArgs: finalNamedArgs,
                typeArgs: typeArgs);
          } else {
            result = Function.apply(
                externalFunc!,
                finalPosArgs,
                finalNamedArgs.map<Symbol, dynamic>(
                    (key, value) => MapEntry(Symbol(key), value)));
          }
        }
        // external class method
        else {
          if (category != FunctionCategory.getter) {
            if (externalFunc == null) {
              if (isStatic || (category == FunctionCategory.constructor)) {
                final classId = klass!.id;
                final externClass = interpreter.fetchExternalClass(classId);
                final funcName = declId.isEmpty ? classId : '$classId.$declId';
                externalFunc = externClass.memberGet(funcName);
              } else {
                throw HTError.missingExternalFunc(id);
              }
            }

            if (externalFunc is HTExternalFunction) {
              result = externalFunc!(
                  positionalArgs: finalPosArgs,
                  namedArgs: finalNamedArgs,
                  typeArgs: typeArgs);
            } else {
              // Use Function.apply will lose type args information.
              result = Function.apply(
                  externalFunc!,
                  finalPosArgs,
                  finalNamedArgs.map<Symbol, dynamic>(
                      (key, value) => MapEntry(Symbol(key), value)));
            }
          } else {
            final classId = klass!.id;
            final externClass = interpreter.fetchExternalClass(classId);
            final funcName = isStatic ? '$classId.$declId' : declId;
            result = externClass.memberGet(funcName);
          }
        }
      }

      // if (category != FunctionCategory.constructor) {
      //   if (returnType != HTType.ANY) {
      //     final encapsulation = interpreter.encapsulate(result);
      //     if (encapsulation.valueType.isNotA(returnType)) {
      //       throw HTError.returnType(
      //           encapsulation.valueType.toString(), id, returnType.toString());
      //     }
      //   }
      // }

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
  dynamic memberGet(String field,
      {String from = SemanticNames.global, bool error = true}) {
    switch (field) {
      case 'valueType':
        return valueType;
      case 'toString':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            '${SemanticNames.function} $id';
      default:
        if (error) {
          throw HTError.undefined(field);
        }
    }
  }
}
