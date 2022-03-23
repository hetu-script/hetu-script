import '../parser/token_reader.dart';

enum StatementType {
  importStmt,
  exportStmt,
}

abstract class HTSemantics {
  StatementType tryParse(TokenReader reader);
}
