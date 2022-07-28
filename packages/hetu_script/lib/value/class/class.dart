import '../../external/external_class.dart';
import '../../grammar/constant.dart';
import '../../error/error.dart';
import '../../interpreter/interpreter.dart';
import '../../type/type.dart';
// import '../declaration.dart';
import '../../value/namespace/namespace.dart';
import '../function/function.dart';
import '../../value/instance/instance.dart';
import '../../declaration/class/class_declaration.dart';
import '../entity.dart';
import 'class_namespace.dart';

/// The Dart implementation of the class declaration in Hetu.
class HTClass extends HTClassDeclaration with HTEntity, InterpreterRef {
  var _instanceIndex = 0;
  int get instanceIndex => _instanceIndex++;

  /// Super class of this class.
  /// If a class is not extends from any super class, then it is extended of class `Object`
  HTClass? superClass;

  HTExternalClass? externalClass;

  /// Mixined class of this class.
  /// Those mixined class can not have any constructors.
  // final Iterable<HTClass> mixinedClass;
  // final Iterable<HTType> mixinedType;

  /// Implemented classes of this class.
  /// Implements only inherits methods declaration,
  /// and the child must re-define all implements methods,
  /// and the re-definition must be of the same function signature.
  // final Iterable<HTClass> implementedClass;
  // final Iterable<HTType> implementedType;

  /// The [HTNamespace] for this class,
  /// for searching for static variables.
  late final HTClassNamespace namespace;

  final bool hasUserDefinedConstructor;

  /// Create a default [HTClass] instance.
  HTClass(
    HTInterpreter interpreter, {
    super.id,
    super.classId,
    HTNamespace? closure,
    super.source,
    super.documentation,
    super.genericTypeParameters = const [],
    super.superType,
    super.withTypes = const [],
    super.implementsTypes = const [],
    super.isExternal = false,
    super.isAbstract = false,
    super.isEnum = false,
    this.superClass,
    this.hasUserDefinedConstructor = false,
  }) : super(closure: closure) {
    namespace = HTClassNamespace(
      klass: this,
      lexicon: interpreter.lexicon,
      id: id,
      classId: classId,
      closure: closure,
      source: source,
    );
    this.interpreter = interpreter;
  }

  @override
  void resolve() {
    super.resolve();
    if (superType != null) {
      superClass = namespace.memberGet(superType!.id!,
          from: namespace.fullName, isRecursive: true);
    }
    if (isExternal) {
      externalClass = interpreter.fetchExternalClass(id!);
    }
    // for (final decl in namespace.declarations.values) {
    //   decl.resolve();
    // }
  }

  @override
  HTClass clone() => HTClass(interpreter,
      id: id,
      classId: classId,
      closure: closure != null ? closure as HTNamespace : null,
      source: source,
      genericTypeParameters: genericTypeParameters,
      superType: superType,
      withTypes: withTypes,
      implementsTypes: implementsTypes,
      isExternal: isExternal,
      isAbstract: isAbstract,
      isEnum: isEnum,
      superClass: superClass);

  /// Create a [HTInstance] of this [HTClass],
  /// will not call constructors
  // HTInstance createInstance({List<HTType> typeArgs = const []}) {
  //   return HTInstance(this, interpreter, typeArgs: typeArgs);
  // }

  // HTInstance createInstanceFromJson(Map<dynamic, dynamic> jsonObject,
  //     {List<HTType> typeArgs = const []}) {
  //   return HTInstance(this, interpreter,
  //       typeArgs: typeArgs,
  //       jsonObject:
  //           jsonObject.map((key, value) => MapEntry(key.toString(), value)));
  // }

  @override
  bool contains(String varName) {
    final getter = '${InternalIdentifier.getter}$varName';
    final setter = '${InternalIdentifier.setter}$varName';
    final constructor = varName != id
        ? '${InternalIdentifier.namedConstructorPrefix}$varName'
        : InternalIdentifier.defaultConstructor;

    return namespace.symbols.containsKey(varName) ||
        namespace.symbols.containsKey(getter) ||
        namespace.symbols.containsKey(setter) ||
        namespace.symbols.containsKey(constructor);
  }

  /// Get a value of a static member from this [HTClass].
  @override
  dynamic memberGet(String varName, {String? from, bool throws = true}) {
    final getter = '${InternalIdentifier.getter}$varName';
    final constructor = '${InternalIdentifier.namedConstructorPrefix}$varName';

    // if (isExternal && !internal) {
    //   final value =
    //       externalClass!.memberGet(varName != id ? '$id.$varName' : varName);
    //   return value;
    // } else {
    if (namespace.symbols.containsKey(varName)) {
      final decl = namespace.symbols[varName]!;
      if (decl.isPrivate &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(varName);
      }
      if (isExternal) {
        decl.resolve();
        return decl.value;
      } else {
        if (decl.isStatic ||
            (decl is HTFunction &&
                decl.category == FunctionCategory.constructor)) {
          decl.resolve();
          return decl.value;
        }
      }
    } else if (namespace.symbols.containsKey(getter)) {
      final decl = namespace.symbols[getter]!;
      if (decl.isPrivate &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(varName);
      }
      final func = decl as HTFunction;
      if (isExternal) {
        decl.resolve();
        return func.call();
      } else {
        if (decl.isStatic) {
          decl.resolve();
          return func.call();
        }
      }
    } else if (namespace.symbols.containsKey(constructor)) {
      final decl = namespace.symbols[constructor]!.value;
      if (decl.isPrivate &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(varName);
      }
      decl.resolve();
      final func = decl as HTFunction;
      return func;
    }
    // }

    if (throws) {
      throw HTError.undefined(varName,
          filename: interpreter.currentFileName,
          line: interpreter.currentLine,
          column: interpreter.currentColumn);
    }
  }

  /// Assign a value to a static member of this [HTClass].
  @override
  void memberSet(String varName, dynamic varValue, {String? from}) {
    final setter = '${InternalIdentifier.setter}$varName';

    if (isExternal) {
      externalClass!.memberSet('$id.$varName', varValue);
      return;
    } else {
      if (namespace.symbols.containsKey(varName)) {
        final decl = namespace.symbols[varName]!;
        if (decl.isStatic) {
          if (decl.isPrivate &&
              from != null &&
              !from.startsWith(namespace.fullName)) {
            throw HTError.privateMember(varName);
          }
          decl.resolve();
          decl.value = varValue;
          return;
        }
        // TODO: non-static error prompt
      } else if (namespace.symbols.containsKey(setter)) {
        final decl = namespace.symbols[setter]!;
        if (decl.isStatic) {
          if (decl.isPrivate &&
              from != null &&
              !from.startsWith(namespace.fullName)) {
            throw HTError.privateMember(varName);
          }
          decl.resolve();
          final setterFunc = decl as HTFunction;
          setterFunc.call(positionalArgs: [varValue]);
          return;
        }
        // TODO: non-static error prompt
      }
    }

    throw HTError.undefined(varName,
        filename: interpreter.currentFileName,
        line: interpreter.currentLine,
        column: interpreter.currentColumn);
  }

  /// Call a static function of this [HTClass].
  dynamic invoke(String funcName,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) {
    try {
      final func = memberGet(funcName);

      if (func is HTFunction) {
        func.resolve();
        return func.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        throw HTError.notCallable(funcName,
            filename: interpreter.currentFileName,
            line: interpreter.currentLine,
            column: interpreter.currentColumn);
      }
    } catch (error, stackTrace) {
      if (interpreter.config.processError) {
        interpreter.processError(error, stackTrace);
      } else {
        rethrow;
      }
    }
  }
}
