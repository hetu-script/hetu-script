import '../../grammar/lexicon.dart';
import '../../grammar/semantic.dart';
import '../../error/error.dart';
import '../../element/declaration.dart';
import '../../interpreter/interpreter.dart';
import '../../type/type.dart';
import '../object.dart';
import '../namespace.dart';
import '../function/function.dart';
import '../instance/instance.dart';
import 'class_declaration.dart';
import 'class_namespace.dart';

/// [HTClass] is the Dart implementation of the class declaration in Hetu.
/// [static] members in Hetu class are stored within a _namespace of [HTClassNamespace].
/// instance members of this class created by [createInstance] are stored in [instanceMembers].
class HTClass extends ClassDeclaration with HTObject, HetuRef {
  @override
  String toString() => '${HTLexicon.CLASS} $id';

  var _instanceIndex = 0;
  int get instanceIndex => _instanceIndex++;

  @override
  HTType get valueType => HTType.CLASS;

  /// The [HTNamespace] for this class,
  /// for searching for static variables.
  final HTClassNamespace namespace;

  /// Super class of this class.
  /// If a class is not extends from any super class, then it is extended of class `Object`
  HTClass? superClass;

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

  /// The instance member variables defined in class definition.
  final instanceMembers = <String, Declaration>{};
  // final Map<String, HTClass> instanceNestedClasses = {};

  /// Create a default [HTClass] instance.
  HTClass(String id, String moduleFullName, String libraryName,
      Hetu interpreter, HTNamespace closure,
      {String? classId,
      Iterable<HTType> genericParameters = const [],
      HTType? superType,
      Iterable<HTType> withTypes = const [],
      Iterable<HTType> implementsTypes = const [],
      bool isExternal = false,
      bool isAbstract = false,
      this.superClass})
      : namespace = HTClassNamespace(id, id, interpreter, closure: closure),
        super(id, moduleFullName, libraryName,
            genericParameters: genericParameters,
            superType: superType,
            withTypes: withTypes,
            implementsTypes: implementsTypes,
            isExternal: isExternal,
            isAbstract: isAbstract) {
    this.interpreter = interpreter;
  }

  @override
  void resolve(HTNamespace namespace) {
    super.resolve(namespace);

    if (superType != null) {
      superClass = namespace.memberGet(superType!.id, from: namespace.fullName);
    }

    for (final decl in this.namespace.declarations.values) {
      decl.resolve(namespace);
    }

    for (final decl in instanceMembers.values) {
      decl.resolve(namespace);
    }
  }

  @override
  HTClass clone() =>
      HTClass(id, moduleFullName, libraryName, interpreter, namespace.closure!,
          classId: classId,
          genericParameters: genericParameters,
          superType: superType,
          withTypes: withTypes,
          implementsTypes: implementsTypes,
          isExternal: isExternal,
          isAbstract: isAbstract,
          superClass: superClass);

  /// Create a [HTInstance] of this [HTClass],
  /// will not call constructors
  HTInstance createInstance({List<HTType> typeArgs = const []}) {
    return HTInstance(this, interpreter, typeArgs: typeArgs);
  }

  HTInstance createInstanceFromJson(Map<dynamic, dynamic> jsonObject,
      {List<HTType> typeArgs = const []}) {
    return HTInstance(this, interpreter,
        typeArgs: typeArgs,
        jsonObject:
            jsonObject.map((key, value) => MapEntry(key.toString(), value)));
  }

  /// Wether there's a member in this [HTClass] by the [varName].
  @override
  bool contains(String varName) =>
      namespace.declarations.containsKey(varName) ||
      namespace.declarations.containsKey('${SemanticNames.getter}$varName') ||
      namespace.declarations.containsKey('$id.$varName');

  /// Get a value of a static member from this [HTClass].
  @override
  dynamic memberGet(String varName,
      {String from = SemanticNames.global, bool error = true}) {
    final getter = '${SemanticNames.getter}$varName';
    final constructor = varName != id
        ? '${SemanticNames.constructor}$varName'
        : SemanticNames.constructor;

    if (isExternal) {
      if (namespace.declarations.containsKey(varName)) {
        if (varName.startsWith(HTLexicon.privatePrefix) &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(varName);
        }
        final decl = namespace.declarations[varName]!;
        return decl.value;
      } else if (namespace.declarations.containsKey(getter)) {
        if (varName.startsWith(HTLexicon.privatePrefix) &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(varName);
        }
        HTFunction func = namespace.declarations[getter]!.value;
        return func.call();
      } else if (namespace.declarations.containsKey(constructor)) {
        if (varName.startsWith(HTLexicon.privatePrefix) &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(varName);
        }
        HTFunction func = namespace.declarations[constructor]!.value;
        return func;
      }
    } else {
      if (namespace.declarations.containsKey(varName)) {
        if (varName.startsWith(HTLexicon.privatePrefix) &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(varName);
        }
        final decl = namespace.declarations[varName]!;
        return decl.value;
      } else if (namespace.declarations.containsKey(getter)) {
        if (varName.startsWith(HTLexicon.privatePrefix) &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(varName);
        }
        HTFunction func = namespace.declarations[getter]!.value;
        return func.call();
      } else if (namespace.declarations.containsKey(constructor)) {
        if (varName.startsWith(HTLexicon.privatePrefix) &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(varName);
        }
        return namespace.declarations[constructor]!.value as HTFunction;
      }
    }

    switch (varName) {
      case 'valueType':
        return valueType;
      // case 'fromJson':
      //   return ({positionalArgs, namedArgs, typeArgs}) {
      //     return createInstanceFromJson(positionalArgs.first,
      //         typeArgs: typeArgs ?? const []);
      //   };
      default:
        if (error) {
          throw HTError.undefined(varName);
        }
    }
  }

  /// Assign a value to a static member of this [HTClass].
  @override
  void memberSet(String varName, dynamic varValue,
      {String from = SemanticNames.global}) {
    final setter = '${SemanticNames.setter}$varName';

    if (isExternal) {
      final externClass = interpreter.fetchExternalClass(id);
      externClass.memberSet('$id.$varName', varValue);
      return;
    } else if (namespace.declarations.containsKey(varName)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(varName);
      }
      final decl = namespace.declarations[varName]!;
      decl.value = varValue;
      return;
    } else if (namespace.declarations.containsKey(setter)) {
      if (varName.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(varName);
      }
      final setterFunc = namespace.declarations[setter] as HTFunction;
      setterFunc.call(positionalArgs: [varValue]);
      return;
    }

    throw HTError.undefined(varName);
  }

  /// Call a static function of this [HTClass].
  dynamic invoke(String funcName,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = true}) {
    try {
      final func = memberGet(funcName, from: namespace.fullName);

      if (func is HTFunction) {
        return func.call(
            positionalArgs: positionalArgs,
            namedArgs: namedArgs,
            typeArgs: typeArgs);
      } else {
        throw HTError.notCallable(funcName);
      }
    } catch (error, stack) {
      if (errorHandled) {
        rethrow;
      } else {
        interpreter.handleError(error, stack);
      }
    }
  }

  /// Add a instance member declaration to this [HTClass].
  void defineInstanceMember(Declaration variable,
      {bool override = false, bool error = true}) {
    if ((!instanceMembers.containsKey(variable.id)) || override) {
      instanceMembers[variable.id] = variable;
    } else {
      if (error) throw HTError.definedRuntime(variable.id);
    }
  }
}
