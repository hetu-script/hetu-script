import 'constants.dart';

class HetuBreak {}

class HetuError {
  String message;

  HetuError([this.message]);

  @override
  String toString() => 'Error: $message';

  static final _warnings = <String>[];

  static void add(String message) => _warnings.add(message);

  static void output() {
    for (var msg in _warnings) {
      print('Warning: $msg');
    }
  }

  static void clear() => _warnings.clear();
}

class HetuErrorSymbolNotFound extends HetuError {
  HetuErrorSymbolNotFound(String symbol, [int lineNumber, int colNumber]) {
    if ((lineNumber != null) && (colNumber != null)) {
      message = '${HetuOutput.UndefinedVariable} "${symbol}" [${lineNumber}-${colNumber}]';
    } else {
      message = '${HetuOutput.UndefinedVariable} "${symbol}"';
    }
  }
}
