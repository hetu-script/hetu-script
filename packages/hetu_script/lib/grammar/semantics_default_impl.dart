import 'semantics.dart';
import '../parser/token_reader.dart';

/// Default semantics implementation used by Hetu.
class HTDefaultSemantics extends HTSemantics {
  @override
  StatementType tryParse(TokenReader reader) {
    return StatementType.importStmt;
  }
}
