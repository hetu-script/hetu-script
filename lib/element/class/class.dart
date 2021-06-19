import '../../grammar/lexicon.dart';
import '../../grammar/semantic.dart';
import '../../error/error.dart';
import '../element.dart';
import '../../interpreter/interpreter.dart';
import '../../type/type.dart';
import '../namespace.dart';
import '../function/function.dart';
import '../instance/instance.dart';
import 'class_declaration.dart';
// import 'class_namespace.dart';

/// The Dart implementation of the class declaration in Hetu.
class HTClass extends HTClassDeclaration with HetuRef {
  @override
  String toString() => '${HTLexicon.CLASS} $id';

  var _instanceIndex = 0;
  int get instanceIndex => _instanceIndex++;

  @override
  HTType get valueType => HTType.CLASS;

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
  final instanceMembers = <String, HTElement>{};
  // final Map<String, HTClass> instanceNestedClasses = {};

  /// Create a default [HTClass] instance.
  HTClass(String id, String moduleFullName, String libraryName,
      Hetu interpreter, HTNamespace closure,
      {String? classId,
      Iterable<HTType> genericParameters = const [],
      HTType? superType,
      Iterable<HTType> withTypes = const [],
      Iterable<HTType> implementsTypes = const [],
      bool isNested = false,
      bool isExternal = false,
      bool isAbstract = false,
      this.superClass})
      : super(id, moduleFullName, libraryName,
            classId: classId,
            genericParameters: genericParameters,
            superType: superType,
            withTypes: withTypes,
            implementsTypes: implementsTypes,
            isNested: isNested,
            isExternal: isExternal,
            isAbstract: isAbstract,
            closure: closure) {
    this.interpreter = interpreter;
  }

  @override
  void resolve() {
    super.resolve(namespace);

    if (superType != null) {
      superClass = namespace.memberGet(superType!.id, from: namespace.fullName);
    }

    for (final decl in declarations.values) {
      decl.resolve(namespace);
    }
  }

  @override
  HTClass clone() =>
      HTClass(id, moduleFullName, libraryName, interpreter, closure!,
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

  /// Get a value of a static member from this [HTClass].
  @override
  dynamic memberGet(String field,
      {String from = SemanticNames.global,
      bool recursive = true,
      bool error = true}) {
    final getter = '${SemanticNames.getter}$field';
    final constructor = field != id
        ? '${SemanticNames.constructor}$field'
        : SemanticNames.constructor;

    if (isExternal) {
      if (namespace.declarations.containsKey(field)) {
        if (field.startsWith(HTLexicon.privatePrefix) &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(field);
        }
        final decl = namespace.declarations[field]!;
        return decl.value;
      } else if (namespace.declarations.containsKey(getter)) {
        if (field.startsWith(HTLexicon.privatePrefix) &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(field);
        }
        HTFunction func = namespace.declarations[getter]!.value;
        return func.call();
      } else if (namespace.declarations.containsKey(constructor)) {
        if (field.startsWith(HTLexicon.privatePrefix) &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(field);
        }
        HTFunction func = namespace.declarations[constructor]!.value;
        return func;
      }
    } else {
      if (namespace.declarations.containsKey(field)) {
        if (field.startsWith(HTLexicon.privatePrefix) &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(field);
        }
        final decl = namespace.declarations[field]!;
        return decl.value;
      } else if (namespace.declarations.containsKey(getter)) {
        if (field.startsWith(HTLexicon.privatePrefix) &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(field);
        }
        HTFunction func = namespace.declarations[getter]!.value;
        return func.call();
      } else if (namespace.declarations.containsKey(constructor)) {
        if (field.startsWith(HTLexicon.privatePrefix) &&
            !from.startsWith(namespace.fullName)) {
          throw HTError.privateMember(field);
        }
        return namespace.declarations[constructor]!.value as HTFunction;
      }
    }

    switch (field) {
      case 'valueType':
        return valueType;
      // case 'fromJson':
      //   return ({positionalArgs, namedArgs, typeArgs}) {
      //     return createInstanceFromJson(positionalArgs.first,
      //         typeArgs: typeArgs ?? const []);
      //   };
      default:
        if (error) {
          throw HTError.undefined(field);
        }
    }
  }

  /// Assign a value to a static member of this [HTClass].
  @override
  void memberSet(String field, dynamic varValue,
      {String from = SemanticNames.global}) {
    final setter = '${SemanticNames.setter}$field';

    if (isExternal) {
      final externClass = interpreter.fetchExternalClass(id);
      externClass.memberSet('$id.$field', varValue);
      return;
    } else if (namespace.declarations.containsKey(field)) {
      if (field.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(field);
      }
      final decl = namespace.declarations[field]!;
      decl.value = varValue;
      return;
    } else if (namespace.declarations.containsKey(setter)) {
      if (field.startsWith(HTLexicon.privatePrefix) &&
          !from.startsWith(namespace.fullName)) {
        throw HTError.privateMember(field);
      }
      final setterFunc = namespace.declarations[setter] as HTFunction;
      setterFunc.call(positionalArgs: [varValue]);
      return;
    }

    throw HTError.undefined(field);
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
  void defineInstanceMember(HTElement variable,
      {bool override = false, bool error = true}) {
    if ((!instanceMembers.containsKey(variable.id)) || override) {
      instanceMembers[variable.id] = variable;
    } else {
      if (error) throw HTError.definedRuntime(variable.id);
    }
  }
}
