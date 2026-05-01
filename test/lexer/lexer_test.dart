import 'package:hetu_script/hetu_script.dart';
import 'package:test/test.dart';

/// Collect all tokens from the lexer's linked list output into a plain list.
List<Token> lexAll(String content) {
  final lexer = HTLexerHetu();
  final head = lexer.lex(content);
  final tokens = <Token>[];
  var token = head;
  while (true) {
    tokens.add(token);
    if (token.lexeme == Token.endOfFile) break;
    token = token.next!;
  }
  return tokens;
}

/// Return just the lexemes of all tokens.
List<String> lexemes(String content) =>
    lexAll(content).map((t) => t.lexeme).toList();

/// Return tokens filtered to only non-whitespace, non-comment, non-empty-line.
List<Token> meaningfulTokens(String content) {
  return lexAll(content)
      .where((t) =>
          t is! TokenComment &&
          t is! TokenEmptyLine &&
          t.lexeme != 'end_of_file')
      .toList();
}

void main() {
  // ============================================================
  // Comments
  // ============================================================
  group('comments', () {
    test('single line comment is parsed', () {
      final tokens = lexAll('// hello\n42');
      final comments =
          tokens.whereType<TokenComment>().where((t) => !t.isMultiLine);
      expect(comments.length, 1);
      expect(comments.first.literal, 'hello');
    });

    test('documentation comment is parsed', () {
      final tokens = lexAll('/// doc text\n42');
      final comments = tokens.whereType<TokenComment>();
      final doc = comments.first;
      expect(doc.isDocumentation, isTrue);
      expect(doc.literal, 'doc text');
    });

    test('trailing comment flag', () {
      final tokens = lexAll('var a = 1 // trail');
      final comments = tokens.whereType<TokenComment>();
      expect(comments.first.isTrailing, isTrue);
    });

    test('multi line comment basic', () {
      final tokens = lexAll('/* simple */ 42');
      final comments =
          tokens.whereType<TokenComment>().where((t) => t.isMultiLine);
      expect(comments.length, 1);
      expect(comments.first.literal, ' simple ');
    });

    test('multi line comment empty', () {
      final tokens = lexAll('/**/ 42');
      final comments =
          tokens.whereType<TokenComment>().where((t) => t.isMultiLine);
      expect(comments.length, 1);
      expect(comments.first.literal, '');
    });

    test('multi line comment spanning lines', () {
      final tokens = lexAll('/* line1\nline2 */ 42');
      final comments =
          tokens.whereType<TokenComment>().where((t) => t.isMultiLine);
      expect(comments.length, 1);
      expect(comments.first.literal, ' line1\nline2 ');
    });

    test('multi line comment does not eat subsequent code', () {
      final meaningful = meaningfulTokens('/* comment */ var a = 1');
      expect(meaningful.length, 4); // var, a, =, 1
      expect(meaningful[0].lexeme, 'var');
      expect(meaningful[1].lexeme, 'a');
      expect(meaningful[2].lexeme, '=');
      expect(meaningful[3].lexeme, '1');
    });
  });

  // ============================================================
  // Numbers
  // ============================================================
  group('number literals', () {
    test('decimal integer', () {
      final tokens = lexAll('42');
      final nums = tokens.whereType<TokenIntegerLiteral>();
      expect(nums.single.literal, 42);
    });

    test('negative decimal integer', () {
      final tokens = lexAll('-42');
      final nums = tokens.whereType<TokenIntegerLiteral>();
      expect(nums.single.literal, -42);
    });

    test('hex integer', () {
      final tokens = lexAll('0xFF');
      final nums = tokens.whereType<TokenIntegerLiteral>();
      expect(nums.single.literal, 255);
    });

    test('negative hex integer', () {
      final tokens = lexAll('-0xFF');
      final nums = tokens.whereType<TokenIntegerLiteral>();
      expect(nums.single.literal, -255);
    });

    test('hex with lowercase', () {
      final tokens = lexAll('0xab');
      final nums = tokens.whereType<TokenIntegerLiteral>();
      expect(nums.single.literal, 171);
    });

    test('float with leading zero', () {
      final tokens = lexAll('0.5');
      final nums = tokens.whereType<TokenFloatLiteral>();
      expect(nums.single.literal, 0.5);
    });

    test('short float without leading zero', () {
      final tokens = lexAll('.4');
      final nums = tokens.whereType<TokenFloatLiteral>();
      expect(nums.single.literal, 0.4);
    });

    test('negative short float', () {
      final tokens = lexAll('-.4');
      final nums = tokens.whereType<TokenFloatLiteral>();
      expect(nums.single.literal, -0.4);
    });

    test('float with full format', () {
      final tokens = lexAll('3.14');
      final nums = tokens.whereType<TokenFloatLiteral>();
      expect(nums.single.literal, 3.14);
    });

    test('number is not lexed as identifier', () {
      final tokens = lexAll('42');
      final ids = tokens.whereType<TokenIdentifier>();
      expect(ids, isEmpty);
    });

    test('multiple numbers in expression', () {
      final meaningful = meaningfulTokens('1 + 2.5 - 0xFF');
      expect(meaningful.whereType<TokenIntegerLiteral>().length, 2);
      expect(meaningful.whereType<TokenFloatLiteral>().length, 1);
    });
  });

  // ============================================================
  // String literals
  // ============================================================
  group('string literals', () {
    test('single quoted string', () {
      final tokens = lexAll("'hello'");
      final strs = tokens.whereType<TokenStringLiteral>();
      expect(strs.single.literal, 'hello');
    });

    test('double quoted string', () {
      final tokens = lexAll('"hello"');
      final strs = tokens.whereType<TokenStringLiteral>();
      expect(strs.single.literal, 'hello');
    });

    test('empty string', () {
      final tokens = lexAll("''");
      final strs = tokens.whereType<TokenStringLiteral>();
      expect(strs.single.literal, '');
    });

    test('string preserves start and end marks', () {
      final tokens = lexAll("'hello'");
      final strs = tokens.whereType<TokenStringLiteral>();
      expect(strs.single.startMark, "'");
      expect(strs.single.endMark, "'");
    });

    test('multiline string preserves newlines in literal', () {
      final tokens = lexAll("'line1\nline2'");
      final strs = tokens.whereType<TokenStringLiteral>();
      expect(strs.single.literal, 'line1\nline2');
    });
  });

  // ============================================================
  // Identifiers
  // ============================================================
  group('identifiers', () {
    test('simple identifier', () {
      final tokens = lexAll('hello');
      final ids = tokens.whereType<TokenIdentifier>();
      expect(ids.single.lexeme, 'hello');
      expect(ids.single.isMarked, isFalse);
    });

    test('backtick identifier', () {
      final tokens = lexAll('`weird name`');
      final ids = tokens.whereType<TokenIdentifier>();
      expect(ids.single.lexeme, '`weird name`');
      expect(ids.single.isMarked, isTrue);
      expect(ids.single.literal, 'weird name');
    });

    test('identifier with underscore prefix', () {
      final tokens = lexAll('_private');
      final ids = tokens.whereType<TokenIdentifier>();
      expect(ids.single.lexeme, '_private');
    });

    test('identifier with hash prefix', () {
      final tokens = lexAll('#private');
      final ids = tokens.whereType<TokenIdentifier>();
      expect(ids.single.lexeme, '#private');
    });

    test('identifier with dollar sign', () {
      final tokens = lexAll(r'$var');
      final ids = tokens.whereType<TokenIdentifier>();
      expect(ids.single.lexeme, r'$var');
    });

    test('unicode identifier', () {
      final tokens = lexAll('变量');
      final ids = tokens.whereType<TokenIdentifier>();
      expect(ids.single.lexeme, '变量');
    });
  });

  // ============================================================
  // Keywords
  // ============================================================
  group('keywords', () {
    test('var is keyword', () {
      final tokens = lexAll('var');
      expect(tokens.first.isKeyword, isTrue);
      expect(tokens.first.lexeme, 'var');
    });

    test('true is boolean literal not keyword', () {
      final tokens = lexAll('true');
      expect(tokens.whereType<TokenBooleanLiteral>().single.literal, isTrue);
    });

    test('false is boolean literal not keyword', () {
      final tokens = lexAll('false');
      expect(tokens.whereType<TokenBooleanLiteral>().single.literal, isFalse);
    });

    test('null is keyword', () {
      final tokens = lexAll('null');
      expect(tokens.first.isKeyword, isTrue);
      expect(tokens.first.lexeme, 'null');
    });

    test('keyword list is non-empty', () {
      final lexicon = HTLexiconHetu();
      expect(lexicon.keywords, isNotEmpty);
      expect(lexicon.keywords.contains('var'), isTrue);
      expect(lexicon.keywords.contains('if'), isTrue);
      expect(lexicon.keywords.contains('for'), isTrue);
    });
  });

  // ============================================================
  // Punctuation / operators
  // ============================================================
  group('punctuation and operators', () {
    test('two-char operators are lexed as single token', () {
      final meaningful = meaningfulTokens('a == b');
      expect(meaningful[1].lexeme, '==');
    });

    test('three-char operators are lexed as single token', () {
      final meaningful = meaningfulTokens('a >>> b');
      expect(meaningful[1].lexeme, '>>>');
    });

    test('strict equality', () {
      final meaningful = meaningfulTokens('a === b');
      expect(meaningful[1].lexeme, '===');
    });

    test('compound assignment', () {
      final meaningful = meaningfulTokens('a += 1');
      expect(meaningful[1].lexeme, '+=');
    });

    test('arrow / return type indicator', () {
      final meaningful = meaningfulTokens('a -> b');
      expect(meaningful[1].lexeme, '->');
    });

    test('fat arrow / single line indicator', () {
      final meaningful = meaningfulTokens('a => b');
      expect(meaningful[1].lexeme, '=>');
    });

    test('end of statement semicolon', () {
      final tokens = lexAll('a; b');
      expect(tokens.any((t) => t.lexeme == ';'), isTrue);
    });

    test('all group openers have matching closers in lexicon', () {
      final lexicon = HTLexiconHetu();
      for (final entry in lexicon.groupClosings.entries) {
        expect(lexicon.punctuations.contains(entry.key), isTrue,
            reason: 'missing opener: ${entry.key}');
        expect(lexicon.punctuations.contains(entry.value), isTrue,
            reason: 'missing closer: ${entry.value}');
      }
    });
  });

  // ============================================================
  // String interpolation
  // ============================================================
  group('string interpolation', () {
    test('simple interpolation', () {
      final tokens = lexAll("'hello \${42}'");
      final interps = tokens.whereType<TokenStringInterpolation>();
      expect(interps.length, 1);
      expect(interps.first.interpolations, isNotEmpty);
    });

    test('interpolation contains expression tokens', () {
      final tokens = lexAll("'\${1 + 2}'");
      final interps = tokens.whereType<TokenStringInterpolation>();
      expect(interps.length, 1);
      // The inner tokens should include the expression 1 + 2
      expect(interps.first.interpolations, isNotEmpty);
    });

    test('plain string without interpolation', () {
      final tokens = lexAll("'hello'");
      final interps = tokens.whereType<TokenStringInterpolation>();
      expect(interps, isEmpty);
      expect(tokens.whereType<TokenStringLiteral>().length, 1);
    });
  });

  // ============================================================
  // End of file
  // ============================================================
  group('end of file', () {
    test('last token is always end_of_file', () {
      final tokens = lexAll('42');
      expect(tokens.last.lexeme, 'end_of_file');
    });

    test('empty input produces only end_of_file', () {
      final tokens = lexAll('');
      expect(tokens.length, 1);
      expect(tokens.first.lexeme, 'end_of_file');
    });

    test('end_of_file links to previous', () {
      final tokens = lexAll('42');
      final eof = tokens.last;
      expect(eof.previous, isNotNull);
      expect(eof.previous!.lexeme, '42');
    });
  });

  // ============================================================
  // Token linked list
  // ============================================================
  group('token linked list', () {
    test('tokens are doubly linked', () {
      final tokens = lexAll('a + b');
      // Skip eof at end for chain check
      final chain = tokens.take(tokens.length - 1).toList();
      for (var i = 0; i < chain.length - 1; i++) {
        expect(chain[i].next, same(chain[i + 1]));
        expect(chain[i + 1].previous, same(chain[i]));
      }
    });

    test('empty line tokens are created for blank lines', () {
      final tokens = lexAll('42\n\n99');
      final empties = tokens.whereType<TokenEmptyLine>();
      expect(empties.length, greaterThanOrEqualTo(1));
    });
  });

  // ============================================================
  // Position tracking
  // ============================================================
  group('line and column tracking', () {
    test('tokens on first line start at line 1', () {
      final meaningful = meaningfulTokens('var x = 1');
      expect(meaningful[0].line, 1);
    });

    test('token offset increases through file', () {
      final meaningful = meaningfulTokens('var x = 1');
      // offsets should be non-decreasing
      for (var i = 1; i < meaningful.length; i++) {
        expect(meaningful[i].offset,
            greaterThanOrEqualTo(meaningful[i - 1].offset));
      }
    });

    test('second line tokens have line 2', () {
      final meaningful = meaningfulTokens('var x\nvar y');
      final secondLineTokens =
          meaningful.where((t) => t.lexeme == 'var').toList();
      expect(secondLineTokens.length, 2);
      expect(secondLineTokens[1].line, 2);
    });
  });

  // ============================================================
  // Integration (existing interpreter tests preserved)
  // ============================================================
  group('number literals -', () {
    final hetu = Hetu(
      config: HetuConfig(printPerformanceStatistics: false),
    );
    hetu.init();

    test('short float', () {
      final result = hetu.eval(r''' -.4 ''');
      expect(result, -.4);
    });
    test('hex number literal', () {
      final result = hetu.eval(r''' -0xFF ''');
      expect(result, -255);
    });
    test('decimal integer', () {
      final result = hetu.eval(r''' 42 ''');
      expect(result, 42);
    });
    test('float with leading zero', () {
      final result = hetu.eval(r''' 0.5 ''');
      expect(result, 0.5);
    });
  });

  group('string literals -', () {
    final hetu = Hetu(
      config: HetuConfig(printPerformanceStatistics: false),
    );
    hetu.init();

    test('escape sequences', () {
      final result = hetu.eval(r''' 'line1\nline2\tend' ''');
      expect(result, 'line1\nline2\tend');
    });
    test('string with quotes', () {
      final result = hetu.eval(r""" 'it\'s fine' """);
      expect(result, "it's fine");
    });
    test('multiline string', () {
      final result = hetu.eval(r'''
        var s = 'first line
second line'
        s
      ''');
      expect(result.contains('first'), isTrue);
    });
  });

  group('comments -', () {
    final hetu = Hetu(
      config: HetuConfig(printPerformanceStatistics: false),
    );
    hetu.init();

    test('single line comment ignored', () {
      final result = hetu.eval(r'''
        // this is a comment
        var a = 42 // trailing comment
        a
      ''');
      expect(result, 42);
    });
    test('documentation comment ignored', () {
      final result = hetu.eval(r'''
        /// This is a doc comment
        100
      ''');
      expect(result, 100);
    });
    test('multi line comment ignored', () {
      final result = hetu.eval(r'''
        /* this is a
           multi line comment */
        200
      ''');
      expect(result, 200);
    });
  });

  group('identifier -', () {
    final hetu = Hetu(
      config: HetuConfig(printPerformanceStatistics: false),
    );
    hetu.init();

    test('backtick identifier', () {
      final result = hetu.eval(r'''
        var `weird name` = 'hello'
        `weird name`
      ''');
      expect(result, 'hello');
    });
    test('private identifier with underscore', () {
      final result = hetu.eval(r'''
        var _private = 'secret'
        _private
      ''');
      expect(result, 'secret');
    });
  });
}
