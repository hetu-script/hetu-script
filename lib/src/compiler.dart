import 'dart:typed_data';

// import 'expression.dart';
// import 'statement.dart';

class Compiler {
  //implements ExprVisitor, StmtVisitor {}
  Uint8List compile(String content) {
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add([0]);

    return bytesBuilder.toBytes();
  }
}
