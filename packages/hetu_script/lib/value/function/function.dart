import '../../binding/external_function.dart';
import '../../error/error.dart';
import '../../grammar/semantic.dart';
import '../../grammar/lexicon.dart';
import '../../source/source.dart';
import '../../interpreter/interpreter.dart';
import '../../interpreter/compiler.dart' show GotoInfo;
import '../../type/type.dart';
import '../../value/instance/instance_namespace.dart';
import '../../value/class/class.dart';
import '../../value/instance/instance.dart';
import '../../value/struct/struct.dart';
import '../../value/namespace/namespace.dart';
import '../../declaration/function/function_declaration.dart';
import '../../declaration/generic/generic_type_parameter.dart';
import '../../type/function_type.dart';
import '../entity.dart';
import 'parameter.dart';
import '../variable/variable.dart';

class RedirectingConstructor {
  /// id of super class's constructor
  // final String callee;
  final String name;

  final String? key;

  /// Holds ips of super class's constructor's positional argumnets
  final List<int> positionalArgsIp;

  /// Holds ips of super class's constructor's named argumnets
  final Map<String, int> namedArgsIp;

  RedirectingConstructor(this.name,
      {this.key,
      this.positionalArgsIp = const [],
      this.namedArgsIp = const {}});
}

/// Bytecode implementation of [TypedFunctionDeclaration].
class HTFunction extends HTFunctionDeclaration
    with HTEntity, HetuRef, GotoInfo {
  HTClass? klass;

  @override
  final Map<String, HTParameter> paramDecls;

  final RedirectingConstructor? redirectingConstructor;

  Function? externalFunc;

  @override
  HTFunctionType get valueType => declType;

  /// Create a standard [HTFunction].
  ///
  /// A [TypedFunctionDeclaration] has to be defined in a [HTNamespace] of an [Interpreter]
  /// before it can be called within a script.
  HTFunction(
      String internalName, String fileName, String moduleName, Hetu interpreter,
      {String? id,
      String? classId,
      HTNamespace? closure,
      HTSource? source,
      bool isExternal = false,
      bool isStatic = false,
      bool isConst = false,
      bool isTopLevel = false,
      FunctionCategory category = FunctionCategory.normal,
      String? externalTypeId,
      List<HTGenericTypeParameter> genericTypeParameters = const [],
      bool hasParamDecls = true,
      this.paramDecls = const {},
      HTType? returnType,
      bool isField = false,
      bool isAbstract = false,
      bool isVariadic = false,
      int minArity = 0,
      int maxArity = 0,
      this.externalFunc,
      int? definitionIp,
      int? definitionLine,
      int? definitionColumn,
      HTNamespace? namespace,
      this.redirectingConstructor,
      this.klass})
      : super(internalName,
            id: id,
            classId: classId,
            closure: closure,
            source: source,
            isExternal: isExternal,
            isStatic: isStatic,
            isConst: isConst,
            isTopLevel: isTopLevel,
            category: category,
            externalTypeId: externalTypeId,
            genericTypeParameters: genericTypeParameters,
            hasParamDecls: hasParamDecls,
            paramDecls: paramDecls,
            returnType: returnType,
            isField: isField,
            isAbstract: isAbstract,
            isVariadic: isVariadic,
            minArity: minArity,
            maxArity: maxArity,
            namespace: namespace) {
    this.interpreter = interpreter;
    this.fileName = fileName;
    this.moduleName = moduleName;
    this.definitionIp = definitionIp;
    this.definitionLine = definitionLine;
    this.definitionColumn = definitionColumn;
  }

  @override
  dynamic get value {
    if (externalTypeId != null) {
      final unwrapFunc = interpreter.unwrapExternalFunctionType(this);
      return unwrapFunc;
    } else {
      return this;
    }
  }

  @override
  void resolve() {
    super.resolve();
    if ((closure != null) && (classId != null) && (klass == null)) {
      klass = closure!.memberGet(classId!, recursive: true);
    }
    if (klass != null &&
        klass!.isExternal &&
        (isStatic || category == FunctionCategory.constructor) &&
        category != FunctionCategory.getter &&
        category != FunctionCategory.setter) {
      final funcName = id != null ? '$classId.$id' : classId!;
      externalFunc = klass!.externalClass!.memberGet(funcName);
    }
  }

  @override
  HTFunction clone() =>
      HTFunction(internalName, fileName, moduleName, interpreter,
          id: id,
          classId: classId,
          closure: closure,
          source: source,
          isExternal: isExternal,
          isStatic: isStatic,
          isConst: isConst,
          isTopLevel: isTopLevel,
          category: category,
          externalTypeId: externalTypeId,
          genericTypeParameters: genericTypeParameters,
          hasParamDecls: hasParamDecls,
          paramDecls: paramDecls,
          returnType: returnType,
          isAbstract: isAbstract,
          isVariadic: isVariadic,
          minArity: minArity,
          maxArity: maxArity,
          externalFunc: externalFunc,
          definitionIp: definitionIp,
          definitionLine: definitionLine,
          definitionColumn: definitionColumn,
          namespace: namespace,
          redirectingConstructor: redirectingConstructor,
          klass: klass);

  HTFunction bind(HTStruct struct) {
    if (category == FunctionCategory.literal) {
      return clone()
        ..namespace = struct.namespace
        ..instance = struct;
    } else {
      throw HTError.binding();
    }
  }

  @override
  dynamic memberGet(String varName, {String? from}) {
    if (varName == HTLexicon.bind) {
      return (HTEntity entity,
          {List<dynamic> positionalArgs = const [],
          Map<String, dynamic> namedArgs = const {},
          List<HTType> typeArgs = const []}) {
        return bind(positionalArgs.first);
      };
    } else {
      throw HTError.undefined(varName);
    }
  }

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
  /// function(posArg1, ...posArg2)
  /// ```
  dynamic call(
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool construct = true,
      bool errorHandled = true}) {
    try {
      interpreter.stackTrace.add(
          '$internalName (${interpreter.fileName}:${interpreter.line}:${interpreter.column})');

      dynamic result;
      // 如果是脚本函数
      if (!isExternal) {
        // if (hasParamDecls) {
        //   if (positionalArgs.length < minArity ||
        //       (positionalArgs.length > maxArity && !isVariadic)) {
        //     throw HTError.arity(internalName, positionalArgs.length, minArity,
        //         filename: interpreter.fileName,
        //         line: interpreter.line,
        //         column: interpreter.column);
        //   }

        //   for (final name in namedArgs.keys) {
        //     if (!paramDecls.containsKey(name)) {
        //       throw HTError.namedArg(name,
        //           filename: interpreter.fileName,
        //           line: interpreter.line,
        //           column: interpreter.column);
        //     }
        //   }
        // }

        if (category == FunctionCategory.constructor && construct) {
          // a class method
          if (klass != null) {
            result =
                instance = HTInstance(klass!, interpreter, typeArgs: typeArgs);
            namespace = (result as HTInstance).namespace;
          }
          // a struct method
          else {
            final prototype = (instance as HTStruct);
            result = instance = prototype.clone();
            namespace = (instance as HTStruct).namespace;
          }
        }

        // callClosure is a temporary closure created everytime a function is called
        final HTNamespace callClosure =
            HTNamespace(id: id, closure: namespace ?? closure);

        // define this and super keyword
        if (instance != null) {
          if (namespace is HTInstanceNamespace) {
            callClosure.define(
                HTLexicon.kSuper,
                HTVariable(HTLexicon.kSuper,
                    value: (namespace as HTInstanceNamespace).next));
          }
          callClosure.define(
              HTLexicon.kThis, HTVariable(HTLexicon.kThis, value: instance));
        }

        var variadicStart = -1;
        HTParameter? variadicParam;
        for (var i = 0; i < paramDecls.length; ++i) {
          var decl = paramDecls.values.elementAt(i).clone();
          final paramId = paramDecls.keys.elementAt(i);
          callClosure.define(paramId, decl);

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

        if (category == FunctionCategory.constructor &&
            redirectingConstructor != null) {
          final name = redirectingConstructor!.name;
          final key = redirectingConstructor!.key;

          late final HTFunction constructor;
          if (klass != null) {
            if (name == HTLexicon.kSuper) {
              final superClass = klass!.superClass!;
              if (key == null) {
                constructor = superClass
                    .namespace.declarations[Semantic.constructor]!.value;
              } else {
                constructor = superClass.namespace
                    .declarations['${Semantic.constructor}$key']!.value;
              }
            } else if (name == HTLexicon.kThis) {
              if (key == null) {
                constructor =
                    klass!.namespace.declarations[Semantic.constructor]!.value;
              } else {
                constructor = klass!.namespace
                    .declarations['${Semantic.constructor}$key']!.value;
              }
            }
            // constructor's context is on this newly created instance
            final instanceNamespace = namespace as HTInstanceNamespace;
            constructor.namespace = instanceNamespace.next!;
            constructor.instance = instance;
          } else {
            if (name == HTLexicon.kThis) {
              final prototype = (instance as HTStruct);
              if (key == null) {
                constructor = prototype.memberGet(Semantic.constructor);
              } else {
                constructor =
                    prototype.memberGet('${Semantic.constructor}$key');
              }
              constructor.instance = instance;
              constructor.namespace = namespace;
            }
          }

          final referCtorPosArgs = [];
          final referCtorPosArgIps = redirectingConstructor!.positionalArgsIp;
          for (var i = 0; i < referCtorPosArgIps.length; ++i) {
            final savedFileName = interpreter.fileName;
            final savedlibraryName = interpreter.bytecodeModule.id;
            final savedNamespace = interpreter.namespace;
            final savedIp = interpreter.bytecodeModule.ip;
            interpreter.newStackFrame(
                filename: fileName,
                moduleName: moduleName,
                namespace: callClosure,
                ip: referCtorPosArgIps[i]);
            final isSpread = interpreter.bytecodeModule.readBool();
            if (!isSpread) {
              final arg = interpreter.execute();
              referCtorPosArgs.add(arg);
            } else {
              final List arg = interpreter.execute();
              referCtorPosArgs.addAll(arg);
            }
            interpreter.restoreStackFrame(
              savedFileName: savedFileName,
              savedModuleName: savedlibraryName,
              savedNamespace: savedNamespace,
              savedIp: savedIp,
            );
          }

          final referCtorNamedArgs = <String, dynamic>{};
          final referCtorNamedArgIps = redirectingConstructor!.namedArgsIp;
          for (final name in referCtorNamedArgIps.keys) {
            final referCtorNamedArgIp = referCtorNamedArgIps[name]!;
            final arg = interpreter.execute(
                filename: fileName,
                moduleName: moduleName,
                ip: referCtorNamedArgIp,
                namespace: callClosure);
            referCtorNamedArgs[name] = arg;
          }

          constructor.call(
              construct: false,
              positionalArgs: referCtorPosArgs,
              namedArgs: referCtorNamedArgs);
        }

        if (definitionIp == null) {
          return result;
        }

        if (category != FunctionCategory.constructor) {
          result = interpreter.execute(
              filename: fileName,
              moduleName: moduleName,
              ip: definitionIp,
              namespace: callClosure,
              function: this,
              line: definitionLine,
              column: definitionColumn);
        } else {
          interpreter.execute(
              filename: fileName,
              moduleName: moduleName,
              ip: definitionIp,
              namespace: callClosure,
              function: this,
              line: definitionLine,
              column: definitionColumn);
        }
      }
      // external function
      else {
        late final List<dynamic> finalPosArgs;
        late final Map<String, dynamic> finalNamedArgs;

        if (hasParamDecls) {
          // TODO: these should be checked in analyzer
          // if (positionalArgs.length < minArity ||
          //     (positionalArgs.length > maxArity && !isVariadic)) {
          //   throw HTError.arity(internalName, positionalArgs.length, minArity,
          //       filename: interpreter.fileName,
          //       line: interpreter.line,
          //       column: interpreter.column);
          // }
          // for (final name in namedArgs.keys) {
          //   if (!paramDecls.containsKey(name)) {
          //     throw HTError.namedArg(name,
          //         filename: interpreter.fileName,
          //         line: interpreter.line,
          //         column: interpreter.column);
          //   }
          // }

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

            finalPosArgs.addAll(variadicArg);
          }
        } else {
          finalPosArgs = positionalArgs;
          finalNamedArgs = namedArgs;
        }

        // a class method
        if (klass != null) {
          // a external class method
          if (klass!.isExternal) {
            if (category != FunctionCategory.getter) {
              final func = externalFunc!;
              if (func is HTExternalFunction) {
                result = func(interpreter.namespace,
                    positionalArgs: finalPosArgs,
                    namedArgs: finalNamedArgs,
                    typeArgs: typeArgs);
              } else {
                result = Function.apply(
                    func,
                    finalPosArgs,
                    finalNamedArgs.map<Symbol, dynamic>(
                        (key, value) => MapEntry(Symbol(key), value)));
              }
            } else {
              result = klass!.externalClass!.memberGet('$classId.$id');
            }
          }
          // a external method in a normal class
          else {
            final func = externalFunc ??
                interpreter.fetchExternalFunction('$classId.$id');
            if (func is HTExternalFunction) {
              if (isStatic || category == FunctionCategory.constructor) {
                result = func(interpreter.namespace,
                    positionalArgs: finalPosArgs,
                    namedArgs: finalNamedArgs,
                    typeArgs: typeArgs);
              } else {
                result = func(instance!,
                    positionalArgs: finalPosArgs,
                    namedArgs: finalNamedArgs,
                    typeArgs: typeArgs);
              }
            } else {
              throw HTError.notCallable(internalName,
                  filename: interpreter.fileName,
                  line: interpreter.line,
                  column: interpreter.column);
            }
          }
        }
        // a external method of a struct
        else if (classId != null) {
          externalFunc ??= interpreter.fetchExternalFunction('$classId.$id');
          final func = externalFunc!;
          if (func is HTExternalFunction) {
            if (isStatic || category == FunctionCategory.constructor) {
              result = func(interpreter.namespace,
                  positionalArgs: finalPosArgs,
                  namedArgs: finalNamedArgs,
                  typeArgs: typeArgs);
            } else {
              result = func(instance!,
                  positionalArgs: finalPosArgs,
                  namedArgs: finalNamedArgs,
                  typeArgs: typeArgs);
            }
          } else {
            result = Function.apply(
                func,
                finalPosArgs,
                finalNamedArgs.map<Symbol, dynamic>(
                    (key, value) => MapEntry(Symbol(key), value)));
          }
        }
        // a toplevel external function
        else {
          externalFunc ??= interpreter.fetchExternalFunction(id!);
          final func = externalFunc!;
          if (func is HTExternalFunction) {
            result = func(interpreter.namespace,
                positionalArgs: finalPosArgs,
                namedArgs: finalNamedArgs,
                typeArgs: typeArgs);
          } else {
            result = Function.apply(
                func,
                finalPosArgs,
                finalNamedArgs.map<Symbol, dynamic>(
                    (key, value) => MapEntry(Symbol(key), value)));
          }
        }
      }

      // TODO: move this into analyzer
      // if (category != FunctionCategory.constructor) {
      //   if (returnType != HTType.ANY) {
      //     final encapsulation = interpreter.encapsulate(result);
      //     if (encapsulation.valueType.isNotA(returnType)) {
      //       throw HTError.returnType(
      //           encapsulation.valueType.toString(), id, returnType.toString());
      //     }
      //   }
      // }

      if (interpreter.stackTrace.isNotEmpty) {
        interpreter.stackTrace.removeLast();
      }

      return result;
    } catch (error, stackTrace) {
      if (errorHandled) {
        rethrow;
      } else {
        interpreter.handleError(error, externalStackTrace: stackTrace);
      }
    }
  }
}
