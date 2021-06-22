import 'dart:typed_data';

import '../element/namespace.dart';

class HTLibrary extends HTNamespace {
  final Uint8List bytes;

  HTLibrary(this.namespaces, this.bytes);
}
