import 'package:hetu_script/declaration/function/abstract_parameter.dart';

import '../../external/external_function.dart';
import '../../error/error.dart';
// import '../../source/source.dart';
import '../../interpreter/interpreter.dart';
import '../../bytecode/goto_info.dart';
import '../../type/type.dart';
import '../../value/instance/instance_namespace.dart';
import '../../value/class/class.dart';
import '../../value/instance/instance.dart';
import '../../value/struct/struct.dart';
import '../../value/namespace/namespace.dart';
import '../../declaration/function/function_declaration.dart';
// import '../../declaration/generic/generic_type_parameter.dart';
import '../../type/function.dart';
import '../entity.dart';
// import 'parameter.dart';
import '../variable/variable.dart';
import '../../common/function_category.dart';
import '../../common/internal_identifier.dart';

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
    with HTEntity, InterpreterRef, GotoInfo {
  HTClass? klass;

  // @override
  // final Map<String, HTParameter> paramDecls;

  final RedirectingConstructor? redirectingConstructor;

  Function? externalFunc;

  @override
  HTFunctionType get valueType => declType;

  /// Create a standard [HTFunction].
  ///
  /// A [TypedFunctionDeclaration] has to be defined in a [HTNamespace] of an [Interpreter]
  /// before it can be called within a script.
  HTFunction(
    String file,
    String module,
    HTInterpreter interpreter, {
    required super.internalName,
    super.id,
    super.classId,
    super.closure,
    super.source,
    super.documentation,
    super.isPrivate,
    super.isExternal,
    super.isStatic,
    super.isConst,
    super.isTopLevel,
    super.isField,
    super.category = FunctionCategory.normal,
    super.externalTypeId,
    super.genericTypeParameters = const [],
    super.hasParamDecls = true,
    super.paramDecls = const {},
    required super.declType,
    super.isAsync,
    super.isAbstract,
    super.isVariadic,
    super.minArity,
    super.maxArity,
    super.namespace,
    this.externalFunc,
    int? ip,
    int? line,
    int? column,
    this.redirectingConstructor,
    this.klass,
  }) {
    this.interpreter = interpreter;
    this.file = file;
    this.module = module;
    this.ip = ip;
    this.line = line;
    this.column = column;
  }

  /// Print function signature to String with function [id] and parameter [id].
  // @override
  // String toString() {
  //   var result = StringBuffer();
  //   result.write(InternalIdentifier.function);
  //   if (id != null) {
  //     result.write(' $id');
  //   }
  //   if (declType.typeArgs.isNotEmpty) {
  //     result.write(interpreter.lexicon.typeParameterStart);
  //     for (var i = 0; i < declType.typeArgs.length; ++i) {
  //       result.write(declType.typeArgs[i]);
  //       if (i < declType.typeArgs.length - 1) {
  //         result.write('${interpreter.lexicon.comma} ');
  //       }
  //     }
  //     result.write(interpreter.lexicon.typeParameterEnd);
  //   }
  //   result.write(interpreter.lexicon.groupExprStart);
  //   var i = 0;
  //   var optionalStarted = false;
  //   var namedStarted = false;
  //   for (final param in paramDecls.values) {
  //     if (param.isVariadic) {
  //       result.write(interpreter.lexicon.variadicArgs + ' ');
  //     }
  //     if (param.isOptional && !optionalStarted) {
  //       optionalStarted = true;
  //       result.write(interpreter.lexicon.optionalPositionalParameterStart);
  //     } else if (param.isNamed && !namedStarted) {
  //       namedStarted = true;
  //       result.write(interpreter.lexicon.codeBlockStart);
  //     }
  //     result.write(param.id);
  //     if (param.declType != null) {
  //       result.write('${interpreter.lexicon.typeIndicator} ${param.declType}');
  //     }
  //     if (i < paramDecls.length - 1) {
  //       result.write('${interpreter.lexicon.comma} ');
  //     }
  //     ++i;
  //   }
  //   if (optionalStarted) {
  //     result.write(interpreter.lexicon.optionalPositionalParameterEnd);
  //   } else if (namedStarted) {
  //     result.write(interpreter.lexicon.codeBlockEnd);
  //   }
  //   result.write(
  //       '${interpreter.lexicon.groupExprEnd} ${interpreter.lexicon.functionReturnTypeIndicator} ' +
  //           returnType.toString());
  //   return result.toString();
  // }

  @override
  dynamic get value {
    if (externalTypeId != null) {
      final unwrapFunc = interpreter.unwrapExternalFunctionType(this);
      return unwrapFunc;
    } else {
      return this;
    }
  }

  void resolveExternal() {
    // free external function & external struct method are handled here.
    final funcName = classId != null ? '$classId.$id' : id!;
    externalFunc = interpreter.fetchExternalFunction(funcName);
  }

  @override
  void resolve({bool resolveType = true}) {
    if (isResolved) return;
    super.resolve();
    if (closure != null && classId != null && klass == null && !isField) {
      klass = closure!.closure!.memberGet(classId!, isRecursive: true);
    }

    if (isExternal) {
      if (klass != null) {
        if (klass!.isExternal) {
          if (category != FunctionCategory.getter &&
              category != FunctionCategory.setter) {
            if (isStatic || category == FunctionCategory.constructor) {
              final funcName = id != null ? '$classId.$id' : classId!;
              externalFunc = klass!.externalClass!.memberGet(funcName);
            } else {
              // for instance members, are handled within HTExternalInstance class.
            }
          }
        } else {
          resolveExternal();
        }
      } else {
        resolveExternal();
      }
    }
  }

  @override
  HTFunction clone() => HTFunction(file, module, interpreter,
      internalName: internalName,
      id: id,
      classId: classId,
      closure: closure != null ? closure as HTNamespace : null,
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
      declType: declType,
      isAbstract: isAbstract,
      isVariadic: isVariadic,
      minArity: minArity,
      maxArity: maxArity,
      externalFunc: externalFunc,
      ip: ip,
      line: line,
      column: column,
      namespace: namespace != null ? namespace as HTNamespace : null,
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

  dynamic apply(HTStruct struct,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    final savedNamespace = namespace;
    final savedInstance = instance;
    namespace = struct.namespace;
    instance = struct;
    final result = call(
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs);
    namespace = savedNamespace;
    instance = savedInstance;
    return result;
  }

  @override
  dynamic memberGet(String id, {String? from}) {
    if (id == interpreter.lexicon.idBind) {
      return (HTEntity entity,
              {List<dynamic> positionalArgs = const [],
              Map<String, dynamic> namedArgs = const {},
              List<HTType> typeArgs = const []}) =>
          bind(positionalArgs.first);
    } else if (id == interpreter.lexicon.idApply) {
      return (HTEntity entity,
              {List<dynamic> positionalArgs = const [],
              Map<String, dynamic> namedArgs = const {},
              List<HTType> typeArgs = const []}) =>
          apply(positionalArgs.first,
              positionalArgs: positionalArgs,
              namedArgs: namedArgs,
              typeArgs: typeArgs);
    } else {
      throw HTError.undefined(id);
    }
  }

  dynamic call(
      {bool useCallingNamespace = true,
      bool createInstance = true,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    // For external async function, don't need this.
    if (isAsync && !isExternal) {
      return Future(() => _call(
            useCallingNamespace: useCallingNamespace,
            createInstance: createInstance,
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs,
          ));
    } else {
      return _call(
        useCallingNamespace: useCallingNamespace,
        createInstance: createInstance,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        typeArgs: typeArgs,
      );
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
  ///
  /// If [createInstance] == true, will create new instance and its namespace.
  dynamic _call(
      {bool useCallingNamespace = true,
      bool createInstance = true,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    try {
      if (isAbstract) {
        throw HTError.abstractFunction(
          internalName,
          filename: interpreter.currentFile,
          line: interpreter.currentLine,
          column: interpreter.currentColumn,
        );
      }

      interpreter.stackTraceList.insert(0,
          '$internalName (${interpreter.currentFile}:${interpreter.currentLine}:${interpreter.currentColumn})');

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

        if (category == FunctionCategory.constructor && createInstance) {
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
        final HTNamespace callClosure = HTNamespace(
            lexicon: interpreter.lexicon,
            id: internalName,
            closure: useCallingNamespace
                ? namespace as HTNamespace?
                : closure as HTNamespace?);

        // define this and super keyword
        if (instance != null) {
          if (namespace is HTInstanceNamespace) {
            callClosure.define(
              interpreter.lexicon.kSuper,
              HTVariable(
                id: interpreter.lexicon.kSuper,
                interpreter: interpreter,
                value: (namespace as HTInstanceNamespace).next,
                closure: callClosure,
              ),
            );
          }
          callClosure.define(
              interpreter.lexicon.kThis,
              HTVariable(
                id: interpreter.lexicon.kThis,
                interpreter: interpreter,
                value: instance,
                closure: callClosure,
              ));
        }

        var variadicStart = -1;
        HTAbstractParameter? variadicParam;
        for (var i = 0; i < paramDecls.length; ++i) {
          var paramDecl = paramDecls.values.elementAt(i).clone();
          final paramId = paramDecls.keys.elementAt(i);
          // omit params with '_' as id
          if (!paramDecl.isNamed &&
              paramId == interpreter.lexicon.omittedMark) {
            continue;
          }
          callClosure.define(paramId, paramDecl);

          if (paramDecl.isVariadic) {
            variadicStart = i;
            variadicParam = paramDecl;
          } else {
            if (i < maxArity) {
              if (i < positionalArgs.length) {
                paramDecl.value = positionalArgs[i];
              } else {
                paramDecl.initialize();
              }
            } else {
              if (namedArgs.containsKey(paramDecl.id)) {
                paramDecl.value = namedArgs[paramDecl.id];
              } else {
                paramDecl.initialize();
              }
            }
            if (paramDecl.isInitialization) {
              result.memberSet(paramDecl.id!, paramDecl.value);
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

        if (category == FunctionCategory.constructor) {
          if (redirectingConstructor == null) {
            if (klass != null) {
              HTClass? superClass = klass!.superClass;
              while (superClass != null && !superClass.isAbstract) {
                // TODO: It is an error that super class doesn't have a default constructor, however this error should be handled in the analyzer.
                final HTFunction constructor = superClass.namespace.memberGet(
                    InternalIdentifier.defaultConstructor,
                    isRecursive: false);
                // constructor's namespace is on this newly created instance
                final instanceNamespace = namespace as HTInstanceNamespace;
                constructor.namespace = instanceNamespace.next!;
                constructor.instance = instance;
                constructor.call(
                    createInstance: false, useCallingNamespace: false);
                superClass = superClass.superClass;
              }
            } else {
              // struct doesn't have chained constructors for now.
            }
          } else {
            final name = redirectingConstructor!.name;
            final key = redirectingConstructor!.key;

            late final HTFunction constructor;
            if (klass != null) {
              if (name == interpreter.lexicon.kSuper) {
                final superClass = klass!.superClass!;
                if (key == null) {
                  constructor = superClass.namespace.memberGet(
                      InternalIdentifier.defaultConstructor,
                      isRecursive: false);
                } else {
                  constructor = superClass.namespace.memberGet(
                      '${InternalIdentifier.namedConstructorPrefix}$key',
                      isRecursive: false);
                }
              } else if (name == interpreter.lexicon.kThis) {
                if (key == null) {
                  constructor = klass!.namespace.memberGet(
                      InternalIdentifier.defaultConstructor,
                      isRecursive: false);
                } else {
                  constructor = klass!.namespace.memberGet(
                      '${InternalIdentifier.namedConstructorPrefix}$key',
                      isRecursive: false);
                }
              }
              // constructor's namespace is on this newly created instance
              final instanceNamespace = namespace as HTInstanceNamespace;
              constructor.namespace = instanceNamespace.next!;
              constructor.instance = instance;
            } else {
              if (name == interpreter.lexicon.kSuper) {
                final proto = (instance as HTStruct).prototype;
                assert(proto != null);
                if (key == null) {
                  constructor =
                      proto!.memberGet(InternalIdentifier.defaultConstructor);
                } else {
                  constructor = proto!.memberGet(
                      '${InternalIdentifier.namedConstructorPrefix}$key');
                }
              } else if (name == interpreter.lexicon.kThis) {
                final obj = (instance as HTStruct);
                if (key == null) {
                  constructor =
                      obj.memberGet(InternalIdentifier.defaultConstructor);
                } else {
                  constructor = obj.memberGet(
                      '${InternalIdentifier.namedConstructorPrefix}$key');
                }
                constructor.instance = instance;
                constructor.namespace = namespace;
              }
            }

            final referCtorPosArgs = [];
            final referCtorPosArgIps = redirectingConstructor!.positionalArgsIp;
            for (var i = 0; i < referCtorPosArgIps.length; ++i) {
              final HTContext savedContext = interpreter.getContext();
              interpreter.setContext(
                context: HTContext(
                  file: file,
                  module: module,
                  namespace: callClosure,
                  ip: referCtorPosArgIps[i],
                ),
              );
              final isSpread = interpreter.currentBytecodeModule.readBool();
              if (!isSpread) {
                final arg = interpreter.execute();
                referCtorPosArgs.add(arg);
              } else {
                final List arg = interpreter.execute();
                referCtorPosArgs.addAll(arg);
              }
              interpreter.setContext(context: savedContext);
            }

            final referCtorNamedArgs = <String, dynamic>{};
            final referCtorNamedArgIps = redirectingConstructor!.namedArgsIp;
            for (final name in referCtorNamedArgIps.keys) {
              final referCtorNamedArgIp = referCtorNamedArgIps[name]!;
              final arg = interpreter.execute(
                context: HTContext(
                    file: file,
                    module: module,
                    ip: referCtorNamedArgIp,
                    namespace: callClosure),
              );
              referCtorNamedArgs[name] = arg;
            }

            constructor.call(
              createInstance: false,
              useCallingNamespace: false,
              positionalArgs: referCtorPosArgs,
              namedArgs: referCtorNamedArgs,
              typeArgs: typeArgs,
            );
          }
        }

        if (ip == null) {
          interpreter.stackTraceList.removeLast();
          return result;
        }

        if (category != FunctionCategory.constructor) {
          result = interpreter.execute(
            context: HTContext(
              file: file,
              module: module,
              ip: ip,
              namespace: callClosure,
              line: line,
              column: column,
            ),
          );
        } else {
          interpreter.execute(
            context: HTContext(
              file: file,
              module: module,
              ip: ip,
              namespace: callClosure,
              line: line,
              column: column,
            ),
          );
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
              // break;
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
                  finalNamedArgs[decl.id!] = decl.value;
                } else {
                  decl.initialize();
                  finalNamedArgs[decl.id!] = decl.value;
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
              assert(externalFunc != null);
              final func = externalFunc!;
              if (func is HTExternalFunction) {
                result = func(interpreter.currentNamespace,
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
            if (interpreter.config.resolveExternalFunctionsDynamically) {
              resolveExternal();
            }
            assert(externalFunc != null);
            final func = externalFunc!;
            if (func is HTExternalFunction) {
              if (isStatic || category == FunctionCategory.constructor) {
                result = func(interpreter.currentNamespace,
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
        }
        // a external method of a struct
        else if (classId != null) {
          if (interpreter.config.resolveExternalFunctionsDynamically) {
            resolveExternal();
          }
          assert(externalFunc != null);
          final func = externalFunc!;
          if (func is HTExternalFunction) {
            if (isStatic || category == FunctionCategory.constructor) {
              result = func(interpreter.currentNamespace,
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
          if (interpreter.config.resolveExternalFunctionsDynamically) {
            resolveExternal();
          }
          assert(externalFunc != null);
          final func = externalFunc!;
          if (func is HTExternalFunction) {
            result = func(interpreter.currentNamespace,
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

      if (interpreter.stackTraceList.isNotEmpty) {
        interpreter.stackTraceList.removeLast();
      }

      if (result is FutureExecution) {
        result = interpreter.waitFutureExucution(result);
      }

      return result;
    } catch (error, stackTrace) {
      if (interpreter.config.processError) {
        interpreter.processError(error, stackTrace);
      } else {
        rethrow;
      }
    }
  }
}
