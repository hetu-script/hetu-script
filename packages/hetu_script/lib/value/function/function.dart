import '../../external/external_function.dart';
import '../../error/error.dart';
import '../../interpreter/interpreter.dart';
import '../../bytecode/goto_info.dart';
import '../../value/instance/instance_namespace.dart';
import '../../value/class/class.dart';
import '../../value/instance/instance.dart';
import '../../value/struct/struct.dart';
import '../../value/namespace/namespace.dart';
import '../../declaration/function/function_declaration.dart';
import '../../type/function.dart';
import '../object.dart';
import '../../common/function_category.dart';
import '../../common/internal_identifier.dart';
import '../value_binding.dart';

class RedirectingConstructor {
  /// id of super class's constructor
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
    with HTObject, InterpreterRef, GotoInfo {
  HTClass? klass;

  final RedirectingConstructor? redirectingConstructor;

  Function? externalFunc;

  @override
  HTFunctionType get valueType => declType;

  HTNamespace? namespace;
  dynamic instance;

  bool _functionResolved = false;

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
    super.explicityNamespaceId,
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
    this.externalFunc,
    int? ip,
    int? line,
    int? column,
    this.redirectingConstructor,
    this.klass,
    this.namespace,
  }) {
    this.interpreter = interpreter;
    this.file = file;
    this.module = module;
    this.ip = ip;
    this.line = line;
    this.column = column;
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

  /// resolve free external function & external struct method.
  void resolveExternal() {
    String funcName;
    if (classId != null) {
      if (category == FunctionCategory.constructor) {
        if (id == null) {
          funcName = '$classId';
        } else {
          funcName = '$classId.$id';
        }
      } else {
        if (id == null) {
          throw HTError.undefined(internalName);
        }
        if (isStatic) {
          funcName = '$classId.$id';
        } else {
          funcName = '$classId::$id';
        }
      }
    } else if (explicityNamespaceId != null) {
      if (id == null) {
        throw HTError.undefined(internalName);
      }
      funcName = '$explicityNamespaceId::$id';
    } else {
      if (id == null) {
        throw HTError.undefined(internalName);
      }
      funcName = id!;
    }
    if (classId != null && funcName.contains('::')) {
      // a external method within a normal class
      externalFunc = interpreter.fetchExternalMethod(funcName);
    } else {
      // other external function
      externalFunc = interpreter.fetchExternalFunction(funcName);
    }
  }

  @override
  void resolve({bool resolveType = true}) {
    if (_functionResolved) return;

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

    _functionResolved = true;
  }

  @override
  HTFunction clone() => HTFunction(
        file,
        module,
        interpreter,
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
        klass: klass,
      );

  HTFunction bind(HTStruct struct) {
    if (category == FunctionCategory.literal) {
      return clone()
        ..namespace = struct.namespace
        ..instance = struct;
    } else {
      throw HTError.binding();
    }
  }

  dynamic apply(
    HTStruct struct, {
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
  }) {
    final savedNamespace = namespace;
    final savedInstance = instance;
    namespace = struct.namespace;
    instance = struct;
    final result = call(
      positionalArgs: positionalArgs,
      namedArgs: namedArgs,
    );
    if (result is Future) {
      return result.then((value) {
        namespace = savedNamespace;
        instance = savedInstance;
        return value;
      });
    } else {
      namespace = savedNamespace;
      instance = savedInstance;
      return result;
    }
  }

  @override
  dynamic memberGet(String id,
      {String? from, bool isRecursive = false, bool ignoreUndefined = false}) {
    if (id == interpreter.lexicon.idBind) {
      return ({positionalArgs, namedArgs}) => bind(positionalArgs.first);
    } else if (id == interpreter.lexicon.idApply) {
      return ({positionalArgs, namedArgs}) {
        assert(positionalArgs.length > 0);
        return apply(
          positionalArgs.first,
          positionalArgs: positionalArgs.sublist(1),
          namedArgs: namedArgs,
        );
      };
    } else if (id == interpreter.lexicon.idCall) {
      return this;
    }

    if (!ignoreUndefined) {
      throw HTError.undefined(id);
    }
  }

  dynamic call({
    bool useCallingNamespace = true,
    bool createInstance = true,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    // List<HTType> typeArgs = const [],
  }) {
    // For external async function, don't need this.
    if (isAsync && !isExternal) {
      return Future(() => _call(
            useCallingNamespace: useCallingNamespace,
            createInstance: createInstance,
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            // typeArgs: typeArgs,
          ));
    } else {
      return _call(
        useCallingNamespace: useCallingNamespace,
        createInstance: createInstance,
        positionalArgs: positionalArgs,
        namedArgs: namedArgs,
        // typeArgs: typeArgs,
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
  dynamic _call({
    bool useCallingNamespace = true,
    bool createInstance = true,
    List<dynamic> positionalArgs = const [],
    Map<String, dynamic> namedArgs = const {},
    // List<HTType> typeArgs = const [],
  }) {
    var stackPushed = false;
    try {
      if (isAbstract) {
        throw HTError.abstractFunction(
          internalName,
          filename: interpreter.currentFile,
          line: interpreter.currentLine,
          column: interpreter.currentColumn,
        );
      }

      interpreter.stackTraceList.add(
          '$internalName (${interpreter.currentFile}:${interpreter.currentLine}:${interpreter.currentColumn})');
      stackPushed = true;

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
            result = instance = HTInstance(
              klass!,
              interpreter,
              // typeArgs: typeArgs,
            );
            namespace = (result as HTInstance).namespace;
          }
          // a struct method
          else {
            final prototype = (instance as HTStruct);
            result = instance = prototype.clone(withInternals: true);
            namespace = (instance as HTStruct).namespace;
          }
        }

        // callClosure is a temporary closure created everytime a function is called
        final HTNamespace callClosure = HTNamespace(
            lexicon: interpreter.lexicon,
            id: internalName,
            closure: useCallingNamespace ? namespace : closure as HTNamespace?);

        // define this and super keyword
        if (instance != null) {
          if (namespace is HTInstanceNamespace) {
            callClosure.define(
              interpreter.lexicon.kSuper,
              HTValueBinding(
                id: interpreter.lexicon.kSuper,
                value: (namespace as HTInstanceNamespace).next,
                isMutable: false,
              ),
            );
          }
          callClosure.define(
            interpreter.lexicon.kThis,
            HTValueBinding(
              id: interpreter.lexicon.kThis,
              value: instance,
              isMutable: false,
            ),
          );
        } else if (category != FunctionCategory.literal) {
          callClosure.define(
            interpreter.lexicon.kThis,
            HTValueBinding(
              id: interpreter.lexicon.kThis,
              value: null,
              isMutable: false,
            ),
          );
        }

        var variadicStart = -1;
        String? variadicParamId;
        for (var i = 0; i < paramDecls.length; ++i) {
          final paramDecl = paramDecls.values.elementAt(i);
          final paramId = paramDecls.keys.elementAt(i);
          // omit params with '_' as id
          if (!paramDecl.isNamed &&
              paramId == interpreter.lexicon.omittedMark) {
            continue;
          }

          if (paramDecl.isVariadic) {
            variadicStart = i;
            variadicParamId = paramId;
            continue;
          }

          dynamic paramValue;
          if (i < maxArity) {
            if (i < positionalArgs.length) {
              paramValue = positionalArgs[i];
            } else {
              paramDecl.resolve();
              paramValue = paramDecl.value;
            }
          } else {
            if (namedArgs.containsKey(paramDecl.id)) {
              paramValue = namedArgs[paramDecl.id];
            } else {
              paramDecl.resolve();
              paramValue = paramDecl.value;
            }
          }

          callClosure.define(paramId, paramValue);

          if (paramDecl.isInitialization) {
            result.memberSet(paramDecl.id!, paramValue);
          }
        }

        if (variadicStart >= 0) {
          final variadicArg = <dynamic>[];
          for (var i = variadicStart; i < positionalArgs.length; ++i) {
            variadicArg.add(positionalArgs[i]);
          }
          callClosure.define(variadicParamId!, variadicArg);
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
                HTContext(
                  file: file,
                  module: module,
                  namespace: callClosure,
                  ip: referCtorPosArgIps[i],
                ),
              );
              final isSpread = interpreter.currentBytecodeModule.readBool();
              if (!isSpread) {
                final arg = interpreter.execute(propagateValue: false);
                referCtorPosArgs.add(arg);
              } else {
                final List arg = interpreter.execute(propagateValue: false);
                referCtorPosArgs.addAll(arg);
              }
              interpreter.setContext(savedContext);
            }

            final referCtorNamedArgs = <String, dynamic>{};
            final referCtorNamedArgIps = redirectingConstructor!.namedArgsIp;
            for (final name in referCtorNamedArgIps.keys) {
              final referCtorNamedArgIp = referCtorNamedArgIps[name]!;
              final arg = interpreter.execute(
                propagateValue: false,
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
              // typeArgs: typeArgs,
            );
          }
        }

        if (ip == null) {
          if (interpreter.stackTraceList.isNotEmpty) {
            interpreter.stackTraceList.removeLast();
          }
          return result;
        }

        if (category != FunctionCategory.constructor) {
          result = interpreter.execute(
            propagateValue: false,
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
            propagateValue: false,
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
      // an external function
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
          var i = 0;
          for (final param in paramDecls.values) {
            if (param.isVariadic) {
              variadicStart = i;
            } else {
              if (i < maxArity) {
                if (i < positionalArgs.length) {
                  finalPosArgs.add(positionalArgs[i]);
                } else {
                  param.resolve();
                  finalPosArgs.add(param.value);
                }
              } else {
                if (namedArgs.containsKey(param.id)) {
                  finalNamedArgs[param.id!] = namedArgs[param.id];
                } else {
                  param.resolve();
                  finalNamedArgs[param.id!] = param.value;
                }
              }
            }

            ++i;
          }

          if (variadicStart >= 0) {
            final variadicArg = <dynamic>[];
            for (var j = variadicStart; j < positionalArgs.length; ++j) {
              variadicArg.add(positionalArgs[j]);
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
              result = _dispatchExternalCall(
                externalFunc!,
                finalPosArgs,
                finalNamedArgs,
                isInstanceCall:
                    !isStatic && category != FunctionCategory.constructor,
                instance: instance,
              );
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
            result = _dispatchExternalCall(
              externalFunc!,
              finalPosArgs,
              finalNamedArgs,
              isInstanceCall:
                  !isStatic && category != FunctionCategory.constructor,
              instance: instance,
            );
          }
        }
        // a external method of a struct
        else if (classId != null) {
          if (interpreter.config.resolveExternalFunctionsDynamically) {
            resolveExternal();
          }
          assert(externalFunc != null);
          result = _dispatchExternalCall(
            externalFunc!,
            finalPosArgs,
            finalNamedArgs,
            isInstanceCall:
                !isStatic && category != FunctionCategory.constructor,
            instance: instance,
          );
        }
        // a toplevel external function
        else {
          if (interpreter.config.resolveExternalFunctionsDynamically) {
            resolveExternal();
          }
          assert(externalFunc != null);
          result = _dispatchExternalCall(
            externalFunc!,
            finalPosArgs,
            finalNamedArgs,
            isInstanceCall: false,
          );
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
      if (stackPushed) {
        interpreter.stackTraceList.removeLast();
      }
      if (interpreter.config.processError) {
        interpreter.processError(error, stackTrace);
      } else {
        rethrow;
      }
    }
  }

  /// Dispatch an external function call, handling both [HTExternalFunction]
  /// and raw Dart [Function] via [Function.apply].
  dynamic _dispatchExternalCall(
    Function func,
    List<dynamic> posArgs,
    Map<String, dynamic> namedArgs, {
    required bool isInstanceCall,
    dynamic instance,
  }) {
    if (isInstanceCall) {
      if (func is HTExternalMethod) {
        return func(
          object: instance,
          positionalArgs: posArgs,
          namedArgs: namedArgs,
        );
      } else {
        return Function.apply(
            func,
            [instance, ...posArgs],
            namedArgs.map<Symbol, dynamic>(
                (key, value) => MapEntry(Symbol(key), value)));
      }
    } else {
      if (func is HTExternalFunction) {
        return func(
          positionalArgs: posArgs,
          namedArgs: namedArgs,
        );
      } else {
        return Function.apply(
            func,
            posArgs,
            namedArgs.map<Symbol, dynamic>(
                (key, value) => MapEntry(Symbol(key), value)));
      }
    }
  }

  String help() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('function $internalName');
    buffer.writeln(interpreter.lexicon.stringify(valueType));
    return buffer.toString();
  }
}
