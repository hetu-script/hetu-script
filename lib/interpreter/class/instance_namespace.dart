import '../../error/errors.dart';
import '../../grammar/lexicon.dart';
import '../../core/abstract_interpreter.dart';
import '../../core/namespace/namespace.dart';
import 'instance.dart';

/// A implementation of [HTNamespace] for [HTInstance].
/// For interpreter searching for symbols within instance methods.
/// [HTInstanceNamespace] is a singly linked list node,
/// it holds its super classes' [HTInstanceNamespace]'s referrences.
class HTInstanceNamespace extends HTNamespace {
  final String? classId;

  final HTInstance instance;

  late final HTInstanceNamespace? next;

  HTInstanceNamespace(String id, this.instance, HTInterpreter interpreter,
      {this.classId, HTNamespace? closure})
      : super(interpreter, id: id, closure: closure);

  /// [HTInstanceNamespace] overrided [HTNamespace]'s [fetch],
  /// with a new named parameter [recursive].
  /// If [recursive] is false, then it won't continue to
  /// try fetching variable from enclosed namespace.
  @override
  dynamic fetch(String varName,
      {String from = HTLexicon.global, bool recursive = true}) {
    final getter = '${HTLexicon.getter}$varName';

    HTInstanceNamespace? curNamespace = this;
    while (curNamespace != null) {
      if (curNamespace.declarations.containsKey(varName) ||
          curNamespace.declarations.containsKey(getter)) {
        return instance.memberGet(varName,
            from: from, classId: curNamespace.classId);
      } else {
        curNamespace = curNamespace.next;
      }
    }

    if (recursive && closure != null) {
      return closure!.fetch(varName, from: from);
    }

    throw HTError.undefined(varName);
  }

  /// [HTInstanceNamespace] overrided [HTNamespace]'s [assign],
  /// with a new named parameter [recursive].
  /// If [recursive] is false, then it won't continue to
  /// try assigning variable from enclosed namespace.
  @override
  void assign(String varName, dynamic varValue,
      {String from = HTLexicon.global, bool recursive = true}) {
    final setter = '${HTLexicon.getter}$varName';

    HTInstanceNamespace? curNamespace = this;
    while (curNamespace != null) {
      if (curNamespace.declarations.containsKey(varName) ||
          curNamespace.declarations.containsKey(setter)) {
        instance.memberSet(varName, varValue,
            from: from, classId: curNamespace.classId);
        return;
      } else {
        curNamespace = curNamespace.next;
      }
    }

    if (recursive && closure != null) {
      closure!.assign(varName, varValue, from: from);
      return;
    }

    throw HTError.undefined(varName);
  }

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) =>
      fetch(varName, from: from, recursive: false);

  @override
  void memberSet(String varName, dynamic varValue,
          {String from = HTLexicon.global}) =>
      assign(varName, varValue, from: from, recursive: false);
}
