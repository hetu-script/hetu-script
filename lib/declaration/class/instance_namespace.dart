import '../../error/error.dart';
import '../../grammar/semantic.dart';
import '../../interpreter/abstract_interpreter.dart';
import '../namespace.dart';
import 'instance.dart';

/// A implementation of [HTNamespace] for [HTInstance].
/// For interpreter searching for symbols within instance methods.
/// [HTInstanceNamespace] is a singly linked list node,
/// it holds its super classes' [HTInstanceNamespace]'s referrences.
class HTInstanceNamespace extends HTNamespace {
  final String? classId;

  final HTInstance instance;

  late final HTInstanceNamespace? next;

  HTInstanceNamespace(String id, this.instance, AbstractInterpreter interpreter,
      {this.classId, HTNamespace? closure})
      : super(interpreter, id: id, closure: closure);

  /// [HTInstanceNamespace] overrided [HTNamespace]'s [memberGet],
  /// with a new named parameter [recursive].
  /// If [recursive] is false, then it won't continue to
  /// try fetching variable from enclosed namespace.
  @override
  dynamic memberGet(String varName,
      {String from = SemanticNames.global,
      bool error = true,
      bool recursive = true}) {
    final getter = '${SemanticNames.getter}$varName';

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
      return closure!.memberGet(varName, from: from);
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
      {String from = SemanticNames.global, bool recursive = true}) {
    final setter = '${SemanticNames.getter}$varName';

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
      closure!.memberSet(varName, varValue, from: from);
      return;
    }

    throw HTError.undefined(varName);
  }
}
