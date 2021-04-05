import 'dart:collection';

import 'object.dart';
import 'interpreter.dart';
import 'class.dart';
import 'type.dart';
import 'errors.dart';
import 'lexicon.dart';
import 'function.dart';
import 'namespace.dart';
import 'common.dart';
import 'variable.dart';
import 'cast.dart';

/// A implementation of [HTNamespace] for [HTInstance].
/// For interpreter searching for symbols within instance methods.
/// [HTInstanceNamespace] is a singly linked list node,
/// it holds its super classes' [HTInstanceNamespace]'s referrences.
class HTInstanceNamespace extends HTNamespace {
  final HTInstance instance;

  HTInstanceNamespace? next;

  HTInstanceNamespace(
      String id, String? classId, this.instance, Interpreter interpreter,
      {HTNamespace? closure})
      : super(interpreter, id: id, classId: classId, closure: closure);

  /// [HTInstanceNamespace] overrided [HTNamespace]'s [fetch],
  /// with a new named parameter [recursive].
  /// If [recursive] is false, then it won't continue to
  /// try fetching variable from enclosed namespace.
  @override
  dynamic fetch(String varName,
      {String from = HTLexicon.global, bool recursive = true}) {
    final getter = '${HTLexicon.getter}$varName';
    if (declarations.containsKey(varName) || declarations.containsKey(getter)) {
      return instance.memberGet(varName, from: from, classId: classId);
    } else {
      if (next != null) {
        return next!.fetch(varName, from: from);
      }
    }

    if (recursive && closure != null) {
      return closure!.fetch(varName, from: from);
    }

    throw HTErrorUndefined(varName);
  }

  /// [HTInstanceNamespace] overrided [HTNamespace]'s [assign],
  /// with a new named parameter [recursive].
  /// If [recursive] is false, then it won't continue to
  /// try assigning variable from enclosed namespace.
  @override
  void assign(String varName, dynamic value,
      {String from = HTLexicon.global, bool recursive = true}) {
    final setter = '${HTLexicon.getter}$varName';
    if (declarations.containsKey(varName) || declarations.containsKey(setter)) {
      return instance.memberSet(varName, value, from: from, classId: classId);
    } else {
      if (next != null) {
        return next!.assign(varName, value, from: from);
      }
    }

    if (recursive && closure != null) {
      closure!.assign(varName, value, from: from);
      return;
    }

    throw HTErrorUndefined(varName);
  }

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) =>
      fetch(varName, from: from, recursive: false);

  @override
  void memberSet(String varName, dynamic value,
          {String from = HTLexicon.global}) =>
      assign(varName, value, from: from, recursive: false);
}

/// The Dart implementation of the instance in Hetu.
/// [HTInstance] carries all decl from its super classes.
/// [HTInstance] inherits all its super classes' [HTTypeID]s.
class HTInstance with HTObject, InterpreterRef {
  late final String id;
  late final String classId;

  late final _typeids = <HTTypeId>[];

  @override
  HTTypeId get typeid => _typeids.first;

  /// A [HTInstance] has all members inherited from all super classes,
  /// Key is the id of a super class.
  /// Value is the namespace of that class.
  /// This map keeps the sequence when insertion,
  /// this way when searches for members, the closest super class's
  /// member always found first.
  final LinkedHashMap<String, HTInstanceNamespace> _namespaces =
      LinkedHashMap();

  HTInstanceNamespace get namespace => _namespaces[classId]!;

  /// Create a default [HTInstance] instance.
  HTInstance(HTClass klass, Interpreter interpreter, int index,
      {List<HTTypeId> typeArgs = const []}) {
    id = '${HTLexicon.instance}$index';
    classId = klass.id;

    HTClass? curKlass = klass;
    var curNamespace = HTInstanceNamespace(id, curKlass.id, this, interpreter,
        closure: klass.namespace);
    while (curKlass != null) {
      curNamespace.next = HTInstanceNamespace(
          id, curKlass.id, this, interpreter,
          closure: klass.namespace);
      curNamespace = curNamespace.next!;

      // TODO: 父类没有type param怎么处理？
      final superTypeId = HTTypeId(curKlass.id);
      _typeids.add(superTypeId);

      // 继承类成员，所有超类的成员都会分别保存
      for (final decl in curKlass.instanceMembers.values) {
        if (decl.id.startsWith(HTLexicon.underscore)) {
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

      curKlass = curKlass.superClass;
    }
  }

  @override
  bool isA(HTTypeId otherTypeId) {
    if (otherTypeId == HTTypeId.ANY) {
      return true;
    } else {
      for (final superTypeId in _typeids) {
        if (superTypeId == otherTypeId) {
          return true;
        }
      }
    }
    return false;
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
            throw HTErrorPrivateMember(varName);
          }

          var decl = space.declarations[varName]!;
          if (decl is HTFunction) {
            if (decl.externalTypedef != null) {
              final externalFunc = interpreter.unwrapExternalFunctionType(
                  decl.externalTypedef!, decl);
              return externalFunc;
            }
            return decl;
          } else if (decl is HTVariable) {
            if (!decl.isInitialized) {
              decl.initialize();
            }
            return decl.value;
          }
        } else if (space.declarations.containsKey(getter)) {
          if (varName.startsWith(HTLexicon.underscore) &&
              !from.startsWith(space.fullName)) {
            throw HTErrorPrivateMember(varName);
          }

          var method = space.declarations[getter]! as HTFunction;
          return method.call();
        }
      }
    } else {
      if (!_namespaces.containsKey(classId)) {
        throw HTErrorNotSuper(classId, interpreter.curSymbol!);
      }

      final space = _namespaces[classId]!;
      if (space.declarations.containsKey(varName)) {
        if (varName.startsWith(HTLexicon.underscore) &&
            !from.startsWith(space.fullName)) {
          throw HTErrorPrivateMember(varName);
        }

        var decl = space.declarations[varName]!;
        if (decl is HTFunction) {
          if (decl.externalTypedef != null) {
            final externalFunc = interpreter.unwrapExternalFunctionType(
                decl.externalTypedef!, decl);
            return externalFunc;
          }
          return decl;
        } else if (decl is HTVariable) {
          if (!decl.isInitialized) {
            decl.initialize();
          }
          return decl.value;
        }
      } else if (space.declarations.containsKey(getter)) {
        if (varName.startsWith(HTLexicon.underscore) &&
            !from.startsWith(space.fullName)) {
          throw HTErrorPrivateMember(varName);
        }

        var method = space.declarations[getter]! as HTFunction;
        return method.call();
      }
    }

    // TODO: 这里应该改成写在脚本的Object上才对
    switch (varName) {
      case 'typeid':
        return typeid;
      case 'toString':
        return (
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTTypeId> typeArgs = const []}) =>
            '${HTLexicon.instanceOf}$typeid';
      default:
        throw HTErrorUndefined(varName);
    }
  }

  /// [HTInstance] overrided [HTObject]'s [memberSet],
  /// with a new named parameter [classId].
  /// If [classId] is provided, then the instance will
  /// only search that [classId]'s corresponed [HTInstanceNamespace].
  @override
  void memberSet(String varName, dynamic value,
      {String from = HTLexicon.global, String? classId}) {
    final setter = '${HTLexicon.setter}$varName';

    if (classId == null) {
      for (final space in _namespaces.values) {
        if (space.declarations.containsKey(varName)) {
          if (varName.startsWith(HTLexicon.underscore) &&
              !from.startsWith(space.fullName)) {
            throw HTErrorPrivateMember(varName);
          }

          var decl = space.declarations[varName]!;
          if (decl is HTVariable) {
            decl.assign(value);
            return;
          } else {
            throw HTErrorImmutable(varName);
          }
        } else if (space.declarations.containsKey(setter)) {
          if (varName.startsWith(HTLexicon.underscore) &&
              !from.startsWith(space.fullName)) {
            throw HTErrorPrivateMember(varName);
          }

          var method = space.declarations[setter]! as HTFunction;
          return method.call(positionalArgs: [value]);
        }
      }
    } else {
      if (!_namespaces.containsKey(classId)) {
        throw HTErrorNotSuper(classId, interpreter.curSymbol!);
      }

      final space = _namespaces[classId]!;
      if (space.declarations.containsKey(varName)) {
        if (varName.startsWith(HTLexicon.underscore) &&
            !from.startsWith(space.fullName)) {
          throw HTErrorPrivateMember(varName);
        }

        var decl = space.declarations[varName]!;
        if (decl is HTVariable) {
          decl.assign(value);
          return;
        } else {
          throw HTErrorImmutable(varName);
        }
      } else if (space.declarations.containsKey(setter)) {
        if (varName.startsWith(HTLexicon.underscore) &&
            !from.startsWith(space.fullName)) {
          throw HTErrorPrivateMember(varName);
        }

        var method = space.declarations[setter]! as HTFunction;
        return method.call(positionalArgs: [value]);
      }
    }

    throw HTErrorUndefined(varName);
  }

  /// Call a member function of this [HTInstance].
  dynamic invoke(String funcName,
      {List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTTypeId> typeArgs = const [],
      bool errorHandled = true}) {
    try {
      HTFunction func = memberGet(funcName, from: namespace.fullName);
      return func.call(
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);
    } catch (error, stack) {
      if (errorHandled) rethrow;

      interpreter.handleError(error, stack);
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
