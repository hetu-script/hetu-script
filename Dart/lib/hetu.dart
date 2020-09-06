/// HETU SCRIPT 0.0.1
///
///
library hetu_script;

import 'package:hetu_script/src/interpreter.dart';

export 'src/common.dart';
export 'src/parser.dart' show ParseStyle;
export 'src/lexer.dart';
export 'src/parser.dart';
export 'src/namespace.dart';
export 'src/interpreter.dart';
export 'src/expression.dart';
export 'src/statement.dart';
export 'src/class.dart';
export 'src/function.dart';
export 'src/errors.dart';

var hetu = Interpreter();
