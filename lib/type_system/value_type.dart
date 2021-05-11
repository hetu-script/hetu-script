import '../implementation/object.dart';
import 'type.dart';

abstract class HTValueType extends HTType with HTObject {
  const HTValueType(String id, {List<HTType> typeArgs = const []})
      : super(id, typeArgs: typeArgs);
}

class HTExternalType extends HTValueType {
  const HTExternalType(String id) : super(id);
}
