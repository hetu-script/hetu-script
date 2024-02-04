import 'type.dart';
import '../value/namespace/namespace.dart';

/// A type checks interfaces rather than type ids.
class HTStructuralType extends HTType {
  late final Map<String, HTType> fieldTypes;

  HTStructuralType({
    required HTNamespace closure,
    Map<String, HTType> fieldTypes = const {},
  }) {
    this.fieldTypes =
        fieldTypes.map((key, value) => MapEntry(key, value.resolve(closure)));
  }

  @override
  bool isA(HTType? other) {
    assert(other?.isResolved ?? true);

    if (other == null) return true;

    if (other.isTop) return true;

    if (other.isBottom) return false;

    if (other is! HTStructuralType) return false;

    if (other.fieldTypes.isEmpty) {
      return true;
    } else {
      for (final key in other.fieldTypes.keys) {
        if (!fieldTypes.containsKey(key)) {
          return false;
        } else {
          if (fieldTypes[key]!.isNotA(other.fieldTypes[key])) {
            return false;
          }
        }
      }
      return true;
    }
  }
}
