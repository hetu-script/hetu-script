// import '../source/source.dart';
import '../source/source_provider.dart';
import '../error/error.dart';
import '../error/error_handler.dart';
import '../grammar/semantic.dart';
import '../grammar/token.dart';

abstract class ParserConfig {}

class ParserConfigImpl implements ParserConfig {}

/// Abstract interface for handling a token list.
abstract class HTAbstractParser {
  // ParserConfig config;

  int _curLine = 0;
  int _curColumn = 0;
  int get curLine => _curLine;
  int get curColumn => _curColumn;

  /// The module current processing, used in error message.
  String? get curModuleFullName;

  String? get curLibraryName;

  var tokPos = 0;

  late Token endOfFile;

  final List<Token> _tokens = [];

  final HTErrorHandler errorHandler;

  final HTSourceProvider sourceProvider;

  HTAbstractParser(
      {HTErrorHandler? errorHandler, HTSourceProvider? sourceProvider})
      : errorHandler = errorHandler ?? DefaultErrorHandler(),
        sourceProvider = sourceProvider ?? DefaultSourceProvider();

  void setTokens(List<Token> tokens) {
    tokPos = 0;
    _tokens.clear();
    _tokens.addAll(tokens);
    _curLine = 0;
    _curColumn = 0;

    endOfFile = Token(
        SemanticNames.endOfFile,
        _tokens.isNotEmpty ? _tokens.last.line + 1 : 0,
        0,
        _tokens.last.offset + 1,
        0);
  }

  /// 检查包括当前Token在内的接下来数个Token是否符合类型要求
  ///
  /// 根据是否符合预期，返回 boolean
  ///
  /// 如果consume为true，则在符合要求时向前移动Token指针
  bool expect(List<String> tokTypes, {bool consume = false}) {
    for (var i = 0; i < tokTypes.length; ++i) {
      if (peek(i).type != tokTypes[i]) {
        return false;
      }
    }
    if (consume) {
      advance(tokTypes.length);
    }
    return true;
  }

  /// 如果当前token符合要求则前进一步，然后返回之前的token，否则抛出异常
  Token match(String tokenType) {
    if (curTok.type != tokenType) {
      final err = HTError.unexpected(tokenType, curTok.lexeme,
          moduleFullName: curModuleFullName,
          line: curTok.line,
          column: curTok.column,
          offset: curTok.offset,
          length: curTok.length);
      errorHandler.handleError(err);
    }

    return advance(1);
  }

  /// 前进指定距离，返回原先位置的Token
  Token advance(int distance) {
    tokPos += distance;
    _curLine = curTok.line;
    _curColumn = curTok.column;
    return peek(-distance);
  }

  /// 获得相对于目前位置一定距离的Token，不改变目前位置
  Token peek(int pos) {
    if ((tokPos + pos) < _tokens.length) {
      return _tokens[tokPos + pos];
    } else {
      return endOfFile;
    }
  }

  /// 获得当前Token
  Token get curTok => peek(0);
}
