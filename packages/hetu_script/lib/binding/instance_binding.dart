import 'package:characters/characters.dart';

// import '../value/object.dart';
// import '../type/type.dart';
import '../error/error.dart';
import '../utils/jsonify.dart';
import '../value/function/function.dart';
import '../utils/collection.dart';

extension StringBinding on String {
  dynamic htFetch(String id) {
    switch (id) {
      case 'characters':
        return Characters(this);
      case 'toString':
        return ({positionalArgs, namedArgs}) => toString();
      case 'compareTo':
        return ({positionalArgs, namedArgs}) => compareTo(positionalArgs[0]);
      case 'codeUnitAt':
        return ({positionalArgs, namedArgs}) => codeUnitAt(positionalArgs[0]);
      case 'length':
        return length;
      case 'endsWith':
        return ({positionalArgs, namedArgs}) => endsWith(positionalArgs[0]);
      case 'startsWith':
        return ({positionalArgs, namedArgs}) =>
            startsWith(positionalArgs[0], positionalArgs[1]);
      case 'indexOf':
        return ({positionalArgs, namedArgs}) =>
            indexOf(positionalArgs[0], positionalArgs[1]);
      case 'lastIndexOf':
        return ({positionalArgs, namedArgs}) =>
            lastIndexOf(positionalArgs[0], positionalArgs[1]);
      case 'isEmpty':
        return isEmpty;
      case 'isNotEmpty':
        return isNotEmpty;
      case 'substring':
        return ({positionalArgs, namedArgs}) =>
            substring(positionalArgs[0], positionalArgs[1]);
      case 'trim':
        return ({positionalArgs, namedArgs}) => trim();
      case 'trimLeft':
        return ({positionalArgs, namedArgs}) => trimLeft();
      case 'trimRight':
        return ({positionalArgs, namedArgs}) => trimRight();
      case 'padLeft':
        return ({positionalArgs, namedArgs}) =>
            padLeft(positionalArgs[0], positionalArgs[1]);
      case 'padRight':
        return ({positionalArgs, namedArgs}) =>
            padRight(positionalArgs[0], positionalArgs[1]);
      case 'contains':
        return ({positionalArgs, namedArgs}) =>
            contains(positionalArgs[0], positionalArgs[1]);
      case 'replaceFirst':
        return ({positionalArgs, namedArgs}) => replaceFirst(
            positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'replaceAll':
        return ({positionalArgs, namedArgs}) =>
            replaceAll(positionalArgs[0], positionalArgs[1]);
      case 'replaceRange':
        return ({positionalArgs, namedArgs}) => replaceRange(
            positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'split':
        return ({positionalArgs, namedArgs}) => split(positionalArgs[0]);
      case 'toLowerCase':
        return ({positionalArgs, namedArgs}) => toLowerCase();
      case 'toUpperCase':
        return ({positionalArgs, namedArgs}) => toUpperCase();
      default:
        throw HTError.undefined(id);
    }
  }
}

/// Binding object for dart [Iterator]
extension IteratorBinding on Iterator {
  dynamic htFetch(String id) {
    switch (id) {
      case 'moveNext':
        return ({positionalArgs, namedArgs}) {
          return moveNext();
        };
      case 'current':
        return current;
      default:
        throw HTError.undefined(id);
    }
  }
}

/// Binding object for dart [Iterable].
extension IterableBinding on Iterable {
  dynamic htFetch(String id) {
    switch (id) {
      case 'toJSON':
        return ({positionalArgs, namedArgs}) => jsonifyList(this);
      case 'iterator':
        return iterator;
      case 'map':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return map((element) {
            return func.call(positionalArgs: [element]);
          });
        };
      case 'where':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return where((element) {
            return func.call(positionalArgs: [element]);
          });
        };
      case 'expand':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return expand((element) {
            return func.call(positionalArgs: [element]) as Iterable;
          });
        };
      case 'contains':
        return ({positionalArgs, namedArgs}) => contains(positionalArgs.first);
      case 'reduce':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return reduce((value, element) {
            return func.call(positionalArgs: [value, element]);
          });
        };
      case 'fold':
        return ({positionalArgs, namedArgs}) {
          final initialValue = positionalArgs[0];
          HTFunction func = positionalArgs[1];
          return fold(initialValue, (value, element) {
            return func.call(positionalArgs: [value, element]);
          });
        };
      case 'every':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return every((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'join':
        return ({positionalArgs, namedArgs}) => join(positionalArgs.first);
      case 'any':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return any((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'toList':
        return ({positionalArgs, namedArgs}) => toList();
      case 'length':
        return length;
      case 'isEmpty':
        return isEmpty;
      case 'isNotEmpty':
        return isNotEmpty;
      case 'take':
        return ({positionalArgs, namedArgs}) => take(positionalArgs.first);
      case 'takeWhile':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return takeWhile((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'skip':
        return ({positionalArgs, namedArgs}) => skip(positionalArgs.first);
      case 'skipWhile':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          return skipWhile((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'first':
        return first;
      case 'last':
        return last;
      case 'single':
        return single;
      case 'firstWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          HTFunction? orElse = namedArgs['orElse'];
          return firstWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, orElse: () {
            return orElse != null ? orElse() : null;
          });
        };
      case 'lastWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          HTFunction? orElse = namedArgs['orElse'];
          return lastWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, orElse: () {
            return orElse != null ? orElse() : null;
          });
        };
      case 'singleWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          HTFunction? orElse = namedArgs['orElse'];
          return singleWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, orElse: () {
            return orElse != null ? orElse() : null;
          });
        };
      case 'elementAt':
        return ({positionalArgs, namedArgs}) => elementAt(positionalArgs.first);
      case 'toString':
        return ({positionalArgs, namedArgs}) => toString();
      default:
        throw HTError.undefined(id);
    }
  }
}

/// Binding object for dart list.
extension ListBinding on List {
  dynamic htFetch(String id) {
    switch (id) {
      case 'add':
        return ({positionalArgs, namedArgs}) => add(positionalArgs.first);
      case 'addAll':
        return ({positionalArgs, namedArgs}) => addAll(positionalArgs.first);
      case 'reversed':
        return reversed;
      case 'indexOf':
        return ({positionalArgs, namedArgs}) =>
            indexOf(positionalArgs[0], positionalArgs[1]);
      case 'lastIndexOf':
        return ({positionalArgs, namedArgs}) =>
            lastIndexOf(positionalArgs[0], positionalArgs[1]);
      case 'insert':
        return ({positionalArgs, namedArgs}) =>
            insert(positionalArgs[0], positionalArgs[1]);
      case 'insertAll':
        return ({positionalArgs, namedArgs}) =>
            insertAll(positionalArgs[0], positionalArgs[1]);
      case 'clear':
        return ({positionalArgs, namedArgs}) => clear();
      case 'remove':
        return ({positionalArgs, namedArgs}) => remove(positionalArgs.first);
      case 'removeAt':
        return ({positionalArgs, namedArgs}) => removeAt(positionalArgs.first);
      case 'removeLast':
        return ({positionalArgs, namedArgs}) => removeLast();
      case 'sublist':
        return ({positionalArgs, namedArgs}) =>
            sublist(positionalArgs[0], positionalArgs[1]);
      case 'asMap':
        return ({positionalArgs, namedArgs}) => asMap();
      case 'sort':
        return ({positionalArgs, namedArgs}) {
          HTFunction? func = positionalArgs.first;
          int Function(dynamic, dynamic)? sortFunc;
          if (func != null) {
            sortFunc = (a, b) {
              return func.call(positionalArgs: [a, b]) as int;
            };
          }
          sort(sortFunc);
        };
      case 'shuffle':
        return ({positionalArgs, namedArgs}) => shuffle();
      case 'indexWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          int start = positionalArgs[1];
          return indexWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, start);
        };
      case 'lastIndexWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          int? start = positionalArgs[1];
          return lastIndexWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          }, start);
        };
      case 'removeWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          removeWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'retainWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          retainWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'getRange':
        return ({positionalArgs, namedArgs}) =>
            getRange(positionalArgs[0], positionalArgs[1]);
      case 'setRange':
        return ({positionalArgs, namedArgs}) => setRange(positionalArgs[0],
            positionalArgs[1], positionalArgs[2], positionalArgs[3]);
      case 'removeRange':
        return ({positionalArgs, namedArgs}) =>
            removeRange(positionalArgs[0], positionalArgs[1]);
      case 'fillRange':
        return ({positionalArgs, namedArgs}) =>
            fillRange(positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'replaceRange':
        return ({positionalArgs, namedArgs}) => replaceRange(
            positionalArgs[0], positionalArgs[1], positionalArgs[2]);
      case 'clone':
        return ({positionalArgs, namedArgs}) => deepCopy(this);
      default:
        // ignore: unnecessary_cast
        return (this as Iterable).htFetch(id);
    }
  }

  dynamic htAssign(String id, dynamic value) {
    switch (id) {
      case 'first':
        first = value;
      case 'last':
        last = value;
      default:
        throw HTError.undefined(id);
    }
  }
}

extension SetBinding on Set {
  dynamic htFetch(String id) {
    switch (id) {
      case 'add':
        return ({positionalArgs, namedArgs}) => add(positionalArgs.first);
      case 'addAll':
        return ({positionalArgs, namedArgs}) => addAll(positionalArgs.first);
      case 'remove':
        return ({positionalArgs, namedArgs}) => remove(positionalArgs.first);
      case 'lookup':
        return ({positionalArgs, namedArgs}) => lookup(positionalArgs[0]);
      case 'removeAll':
        return ({positionalArgs, namedArgs}) => removeAll(positionalArgs.first);
      case 'retainAll':
        return ({positionalArgs, namedArgs}) => retainAll(positionalArgs.first);
      case 'removeWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          removeWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'retainWhere':
        return ({positionalArgs, namedArgs}) {
          HTFunction func = positionalArgs.first;
          retainWhere((element) {
            return func.call(positionalArgs: [element]) as bool;
          });
        };
      case 'containsAll':
        return ({positionalArgs, namedArgs}) =>
            containsAll(positionalArgs.first);
      case 'intersection':
        return ({positionalArgs, namedArgs}) =>
            intersection(positionalArgs.first);
      case 'union':
        return ({positionalArgs, namedArgs}) => union(positionalArgs.first);
      case 'difference':
        return ({positionalArgs, namedArgs}) =>
            difference(positionalArgs.first);
      case 'clear':
        return ({positionalArgs, namedArgs}) => clear();
      case 'toSet':
        return ({positionalArgs, namedArgs}) => toSet();
      default:
        // ignore: unnecessary_cast
        return (this as Iterable).htFetch(id);
    }
  }
}
