abstract class HTGrammarConfig {
  bool get isLexiconCaseSensitive;

  factory HTGrammarConfig({bool isLexiconCaseSensitive}) = HTGrammarConfigImpl;
}

class HTGrammarConfigImpl implements HTGrammarConfig {
  @override
  final bool isLexiconCaseSensitive;

  HTGrammarConfigImpl({this.isLexiconCaseSensitive = true});
}

/// generate semantic definition from [BNF rules](https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form).
class HTGrammarGenerator {}
