import 'dart:typed_data';
import 'dart:convert';

// import 'expression.dart';
// import 'statement.dart';

import 'operator.dart';

class Trunk {
  /// 常量表
  final List<int> constInt64Table;
  final List<double> constFloat64Table;
  final List<String> constStringTable;

  final Uint8List bytes;

  Trunk(this.bytes,
      [this.constInt64Table = const [], this.constFloat64Table = const [], this.constStringTable = const []]);
}

class Compiler {
  static const hetuSignatureData = [8, 5, 20, 21];
  static const hetuSignature = 134550549;
  static const hetuVersionData = [0, 1, 0, 0, 0, 0];

  //implements ExprVisitor, StmtVisitor {}
  Uint8List compile(String content) {
    final bytesBuilder = BytesBuilder();
    // 河图字节码标记
    bytesBuilder.add(hetuSignatureData);
    // 版本号
    bytesBuilder.add(hetuVersionData);

    bytesBuilder.addByte(HT_Operator.constInt64Table);
    bytesBuilder.add(_int64(3));
    bytesBuilder.add(_int64(42));
    bytesBuilder.add(_int64(1979));
    bytesBuilder.add(_int64(3456921));

    bytesBuilder.addByte(HT_Operator.constFloat64Table);
    bytesBuilder.add(_int64(2));
    bytesBuilder.add(_float64(0.2));
    bytesBuilder.add(_float64(3.1415926535897932384626));

    bytesBuilder.addByte(HT_Operator.constUtf8StringTable);
    bytesBuilder.add(_int64(2));
    bytesBuilder.add(_string('hello'));
    bytesBuilder.add(_string('world!'));

    bytesBuilder.addByte(0);

    return bytesBuilder.toBytes();
  }

  Uint8List _int64(int value) => Uint8List(8)..buffer.asByteData().setInt64(0, value, Endian.big);

  Uint8List _float64(double value) => Uint8List(8)..buffer.asByteData().setFloat64(0, value, Endian.big);

  Uint8List _string(String value) {
    final bytesBuilder = BytesBuilder();
    final stringData = utf8.encoder.convert(value);
    bytesBuilder.add(_int64(stringData.length));
    bytesBuilder.add(stringData);
    return bytesBuilder.toBytes();
  }
}
