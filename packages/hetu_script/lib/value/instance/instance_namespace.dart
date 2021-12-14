import 'package:hetu_script/value/function/function.dart';

import '../../error/error.dart';
import '../../grammar/semantic.dart';
import '../../declaration/namespace/namespace.dart';
import 'instance.dart';

/// A implementation of [HTNamespace] for [HTInstance].
/// For interpreter searching for symbols within instance methods.
/// [HTInstanceNamespace] is a linked list node,
/// it holds its super classes' [HTInstanceNamespace]'s referrences.
class HTInstanceNamespace extends HTNamespace {
  final HTInstance instance;

  late final HTInstanceNamespace? next;

  HTInstanceNamespace(String id, this.instance,
      {String? classId, HTNamespace? closure})
      : super(id: id, classId: classId, closure: closure);

  /// [HTInstanceNamespace] overrided [HTNamespace]'s [memberGet],
  /// with a new named parameter [recursive].
  /// If [recursive] is false, then it won't continue to
  /// try fetching variable from enclosed namespace.
  @override
  dynamic memberGet(String varName,
      {bool error = true, bool recursive = true}) {
    final getter = '${Semantic.getter}$varName';

    HTInstanceNamespace? curNamespace = this;
    while (curNamespace != null) {
      if (curNamespace.declarations.containsKey(varName) ||
          curNamespace.declarations.containsKey(getter)) {
        final value = instance.memberGet(varName, cast: curNamespace.classId);
        if (value is HTFunction) {
          value.instance = instance;
        }
        return value;
      } else {
        curNamespace = curNamespace.next;
      }
    }

    if (recursive && closure != null) {
      return closure!.memberGet(varName);
    }

    if (error) {
      throw HTError.undefined(varName);
    }
  }

  /// [HTInstanceNamespace] overrided [HTNamespace]'s [memberSet],
  /// with a new named parameter [recursive].
  /// If [recursive] is false, then it won't continue to
  /// try assigning variable from enclosed namespace.
  @override
  void memberSet(String varName, dynamic varValue,
      {bool recursive = true, bool error = true}) {
    final setter = '${Semantic.getter}$varName';

    HTInstanceNamespace? curNamespace = this;
    while (curNamespace != null) {
      if (curNamespace.declarations.containsKey(varName) ||
          curNamespace.declarations.containsKey(setter)) {
        instance.memberSet(varName, varValue, cast: curNamespace.classId);
        return;
      } else {
        curNamespace = curNamespace.next;
      }
    }

    if (recursive && closure != null) {
      closure!.memberSet(varName, varValue);
      return;
    }

    throw HTError.undefined(varName);
  }
}
