import '../../binding/external_class.dart';
import '../../grammar/lexicon.dart';
import '../../grammar/semantic.dart';
import '../../error/error.dart';
import '../../source/source.dart';
import '../../interpreter/interpreter.dart';
import '../../type/type.dart';
// import '../declaration.dart';
import '../../value/namespace/namespace.dart';
import '../function/function.dart';
import '../../value/instance/instance.dart';
import '../../declaration/class/class_declaration.dart';
import '../entity.dart';
import '../../declaration/generic/generic_type_parameter.dart';
import 'class_namespace.dart';

/// The Dart implementation of the class declaration in Hetu.
class HTClass extends HTClassDeclaration with HTEntity, HetuRef {
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
  final HTClassNamespace namespace;

  /// Create a default [HTClass] instance.
  HTClass(Hetu interpreter,
      {String? id,
      String? classId,
      HTNamespace? closure,
      HTSource? source,
      List<HTGenericTypeParameter> genericTypeParameters = const [],
      HTType? superType,
      Iterable<HTType> withTypes = const [],
      Iterable<HTType> implementsTypes = const [],
      bool isExternal = false,
      bool isAbstract = false,
      bool isEnum = false,
      this.superClass})
      : namespace = HTClassNamespace(
            id: id, classId: classId, closure: closure, source: source),
        super(
            id: id,
            classId: classId,
            closure: closure,
            source: source,
            genericTypeParameters: genericTypeParameters,
            superType: superType,
            withTypes: withTypes,
            implementsTypes: implementsTypes,
            isExternal: isExternal,
            isAbstract: isAbstract,
            isEnum: isEnum) {
    this.interpreter = interpreter;
  }

  @override
  void resolve() {
    super.resolve();
    if (superType != null) {
      superClass = namespace.memberGet(superType!.id,
          from: namespace.fullName, recursive: true);
    }
    if (isExternal) {
      externalClass = interpreter.fetchExternalClass(id!);
    }
    for (final decl in namespace.declarations.values) {
      decl.resolve();
    }
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
    final getter = '${Semantic.getter}$varName';
    final setter = '${Semantic.setter}$varName';
    final constructor = varName != id
        ? '${Semantic.constructor}${HTLexicon.privatePrefix}$varName'
        : Semantic.constructor;

    return namespace.declarations.containsKey(varName) ||
        namespace.declarations.containsKey(getter) ||
        namespace.declarations.containsKey(setter) ||
        namespace.declarations.containsKey(constructor);
  }

  /// Get a value of a static member from this [HTClass].
  @override
  dynamic memberGet(String varName, {String? from, bool error = true}) {
    final getter = '${Semantic.getter}$varName';
    final constructor =
        '${Semantic.constructor}${HTLexicon.privatePrefix}$varName';

    // if (isExternal && !internal) {
    //   final value =
    //       externalClass!.memberGet(varName != id ? '$id.$varName' : varName);
    //   return value;
    // } else {
    if (namespace.declarations.containsKey(varName)) {
      final decl = namespace.declarations[varName]!;
      if (decl.isPrivate &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(varName);
      }
      if (isExternal) {
        return decl.value;
      } else {
        if (decl.isStatic ||
            (decl is HTFunction &&
                decl.category == FunctionCategory.constructor)) {
          return decl.value;
        }
      }
    } else if (namespace.declarations.containsKey(getter)) {
      final decl = namespace.declarations[getter]!;
      if (decl.isPrivate &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(varName);
      }
      final func = decl as HTFunction;
      if (isExternal) {
        return func.call();
      } else {
        if (decl.isStatic) {
          return func.call();
        }
      }
    } else if (namespace.declarations.containsKey(constructor)) {
      final decl = namespace.declarations[constructor]!.value;
      if (decl.isPrivate &&
          from != null &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(varName);
      }
      final func = decl as HTFunction;
      return func;
    }
    // }

    if (error) {
      throw HTError.undefined(varName,
          filename: interpreter.fileName,
          line: interpreter.line,
          column: interpreter.column);
    }
  }

  /// Assign a value to a static member of this [HTClass].
  @override
  void memberSet(String varName, dynamic varValue, {String? from}) {
    final setter = '${Semantic.setter}$varName';

    if (isExternal) {
      externalClass!.memberSet('$id.$varName', varValue);
      return;
    } else {
      if (namespace.declarations.containsKey(varName)) {
        final decl = namespace.declarations[varName]!;
        if (decl.isPrivate &&
            from != null &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(varName);
        }
        if (decl.isStatic) {
          decl.value = varValue;
          return;
        }
      } else if (namespace.declarations.containsKey(setter)) {
        final decl = namespace.declarations[setter]!;
        if (decl.isPrivate &&
            from != null &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(varName);
        }
        if (decl.isStatic) {
          final setterFunc = decl as HTFunction;
          setterFunc.call(positionalArgs: [varValue]);
          return;
        }
      }
    }

    throw HTError.undefined(varName,
        filename: interpreter.fileName,
        line: interpreter.line,
        column: interpreter.column);
  }

  /// Call a static function of this [HTClass].
  dynamic invoke(String funcName,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = true}) {
    try {
      final func = memberGet(funcName);

      if (func is HTFunction) {
        return func.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        throw HTError.notCallable(funcName,
            filename: interpreter.fileName,
            line: interpreter.line,
            column: interpreter.column);
      }
    } catch (error, stackTrace) {
      if (errorHandled) {
        rethrow;
      } else {
        interpreter.handleError(error, externalStackTrace: stackTrace);
      }
    }
  }
}
