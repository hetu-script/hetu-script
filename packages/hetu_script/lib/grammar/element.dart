import '../parser/token.dart';

abstract class SemanticElement {
  SemanticElement();
}

class SequencePart {
  final bool isOptional;

  SequencePart({this.isOptional = false});
}

class Sequence {
  final List<SequencePart> parts;

  Sequence({required this.parts});
}

class Choice {
  final List<SemanticElement> parts;

  Choice({required this.parts});
}

class IdentifierElement extends SemanticElement {
  TokenIdentifier token;

  IdentifierElement(this.token);
}
