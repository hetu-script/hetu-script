// import '../grammar/constant.dart';
import 'type.dart';

// An unknown object type passed into script from other language
class HTExternalType extends HTType {
  const HTExternalType(super.id);

  @override
  bool isA(HTType? other) {
    if (other == null) return true;

    if (other is HTExternalType && id == other.id) return true;

    return false;
  }
}
