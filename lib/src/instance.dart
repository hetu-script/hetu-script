import 'dart:collection';

import 'package:hetu_script/src/declaration.dart';

import 'object.dart';
import 'interpreter.dart';
import 'class.dart';
import 'type.dart';
import 'errors.dart';
import 'lexicon.dart';
import 'function.dart';
import 'namespace.dart';
import 'common.dart';
import 'cast.dart';

/// The Dart implementation of the instance in Hetu.
/// [HTInstance] carries all decl from its super classes.
/// [HTInstance] inherits all its super classes' [HTTypeID]s.
class HTInstance with HTObject, InterpreterRef {
  late final String id;

  @override
  late final HTInstanceType rtType;

  String get classId => rtType.typeName;

  /// A [HTInstance] has all members inherited from all super classes,
  /// Key is the id of a super class.
  /// Value is the namespace of that class.
  /// This map keeps the sequence when insertion,
  /// this way when searches for members, the closest super class's
  /// member always found first.
  final LinkedHashMap<String, HTInstanceNamespace> _namespaces =
      LinkedHashMap();

  /// The [HTNamespace] for this instance.
  /// Variables will start from the lowest class,
  /// searching through all super classes.
  HTInstanceNamespace get namespace => _namespaces[classId]!;

  /// Create a default [HTInstance] instance.
  HTInstance(HTClass klass, Interpreter interpreter,
      {List<HTType> typeArgs = const []}) {
    id = '${HTLexicon.instance}${klass.instanceIndex}';

    var firstClass = true;
    HTClass? curKlass = klass;
    final extended = <HTType>[];
    var curNamespace = HTInstanceNamespace(id, curKlass.id, this, interpreter,
        closure: klass.namespace);
    while (curKlass != null) {
      curNamespace.next = HTInstanceNamespace(
          id, curKlass.id, this, interpreter,
          closure: klass.namespace);
      curNamespace = curNamespace.next!;

      // 继承类成员，所有超类的成员都会分别保存
      for (final decl in curKlass.instanceMembers.values) {
        if (decl.id.startsWith(HTLexicon.underscore) && !firstClass) {
          continue;
        }
        final clone = decl.clone();
        if (clone is HTFunction && clone.funcType != FunctionType.literal) {
          clone.context = curNamespace;
        }
        // TODO: check if override, and if so, check the type wether fits super's type.
        curNamespace.define(clone);
      }

      _namespaces[curKlass.id] = curNamespace;

      if (curKlass.superClassType != null) {
        extended.add(curKlass.superClassType!);
      }
      curKlass = curKlass.superClass;

      firstClass = false;
    }

    rtType = HTInstanceType(klass.id, typeArgs: typeArgs, extended: extended);
  }

  @override
  String toString() {
    final func = memberGet('toString');
    if (func is HTFunction) {
      return func.call();
    } else if (func is Function) {
      return func();
    } else {
      return id;
    }
  }

  @override
  bool contains(String varName) {
    for (final space in _namespaces.values) {
      if (space.declarations.containsKey(varName) ||
          space.declarations.containsKey('${HTLexicon.getter}$varName') ||
          space.declarations.containsKey('${HTLexicon.setter}$varName')) {
        return true;
      }
    }
    return false;
  }

  /// [HTInstance] overrided [HTObject]'s [memberGet],
  /// with a new named parameter [classId].
  /// If [classId] is provided, then the instance will
  /// only search that [classId]'s corresponed [HTInstanceNamespace].
  @override
  dynamic memberGet(String varName,
      {String from = HTLexicon.global, String? classId}) {
    final getter = '${HTLexicon.getter}$varName';

    if (classId == null) {
      for (final space in _namespaces.values) {
        if (space.declarations.containsKey(varName)) {
          if (varName.startsWith(HTLexicon.underscore) &&
              !from.startsWith(space.fullName)) {
            throw HTError.privateMember(varName);
          }

          var decl = space.declarations[varName]!;
          return HTDeclaration.fetch(decl, interpreter);
        } else if (space.declarations.containsKey(getter)) {
          if (varName.startsWith(HTLexicon.underscore) &&
              !from.startsWith(space.fullName)) {
            throw HTError.privateMember(varName);
          }

          var method = space.declarations[getter]! as HTFunction;
          return method.call();
        }
      }
    } else {
      if (!_namespaces.containsKey(classId)) {
        throw HTError.notSuper(classId, interpreter.curSymbol!);
      }

      final space = _namespaces[classId]!;
      if (space.declarations.containsKey(varName)) {
        if (varName.startsWith(HTLexicon.underscore) &&
            !from.startsWith(space.fullName)) {
          throw HTError.privateMember(varName);
        }

        var decl = space.declarations[varName]!;
        return HTDeclaration.fetch(decl, interpreter);
      } else if (space.declarations.containsKey(getter)) {
        if (varName.startsWith(HTLexicon.underscore) &&
            !from.startsWith(space.fullName)) {
          throw HTError.privateMember(varName);
        }

        var method = space.declarations[getter]! as HTFunction;
        return method.call();
      }
    }

    // TODO: 这里应该改成写在脚本的Object上才对
    switch (varName) {
      case 'runtimeType':
        return rtType;
      case 'toString':
        return ({positionalArgs, namedArgs, typeArgs}) =>
            '${HTLexicon.instanceOf}$rtType';
      default:
        throw HTError.undefined(varName);
    }
  }

  /// [HTInstance] overrided [HTObject]'s [memberSet],
  /// with a new named parameter [classId].
  /// If [classId] is provided, then the instance will
  /// only search that [classId]'s corresponed [HTInstanceNamespace].
  @override
  void memberSet(String varName, dynamic varValue,
      {String from = HTLexicon.global, String? classId}) {
    final setter = '${HTLexicon.setter}$varName';

    if (classId == null) {
      for (final space in _namespaces.values) {
        if (space.declarations.containsKey(varName)) {
          if (varName.startsWith(HTLexicon.underscore) &&
              !from.startsWith(space.fullName)) {
            throw HTError.privateMember(varName);
          }

          var decl = space.declarations[varName]!;
          HTDeclaration.assign(decl, varValue);
          return;
        } else if (space.declarations.containsKey(setter)) {
          if (varName.startsWith(HTLexicon.underscore) &&
              !from.startsWith(space.fullName)) {
            throw HTError.privateMember(varName);
          }

          var method = space.declarations[setter]! as HTFunction;
          method.call(positionalArgs: [varValue]);
          return;
        }
      }
    } else {
      if (!_namespaces.containsKey(classId)) {
        throw HTError.notSuper(classId, interpreter.curSymbol!);
      }

      final space = _namespaces[classId]!;
      if (space.declarations.containsKey(varName)) {
        if (varName.startsWith(HTLexicon.underscore) &&
            !from.startsWith(space.fullName)) {
          throw HTError.privateMember(varName);
        }

        var decl = space.declarations[varName]!;
        HTDeclaration.assign(decl, varValue);
        return;
      } else if (space.declarations.containsKey(setter)) {
        if (varName.startsWith(HTLexicon.underscore) &&
            !from.startsWith(space.fullName)) {
          throw HTError.privateMember(varName);
        }

        var method = space.declarations[setter]! as HTFunction;
        method.call(positionalArgs: [varValue]);
        return;
      }
    }

    throw HTError.undefined(varName);
  }

  /// Call a member function of this [HTInstance].
  dynamic invoke(String funcName,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const [],
      bool errorHandled = true}) {
    try {
      HTFunction func = memberGet(funcName, from: namespace.fullName);
      return func.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);
    } catch (error, stack) {
      if (errorHandled) {
        rethrow;
      } else {
        interpreter.handleError(error, stack);
      }
    }
  }

  @override
  bool operator ==(Object other) {
    if (other is HTCast) {
      return this == other.object;
    }
    return hashCode == other.hashCode;
  }
}
