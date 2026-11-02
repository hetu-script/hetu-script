import '../ast/ast.dart';
import '../lexicon/lexicon.dart';
import '../lexicon/lexicon_hetu.dart';
import '../optimization/optimization_result.dart';

class HTConstantValue {
  final Object value;

  const HTConstantValue(this.value);
}

class HTConstantFolder {
  final HTLexicon _lexicon;
  final Set<ASTNode> _visitingDeclarations = Set<ASTNode>.identity();

  HTConstantFolder({HTLexicon? lexicon})
      : _lexicon = lexicon ?? HTLexiconHetu();

  HTConstantValue? fold(ASTNode node, HTOptimizationResult optimization) {
    if (node is ASTLiteralBoolean ||
        node is ASTLiteralInteger ||
        node is ASTLiteralFloat) {
      return HTConstantValue(node.value as Object);
    }
    if (node is ASTLiteralString) {
      return HTConstantValue(_escape(node.value));
    }
    if (node is ASTStringInterpolation) {
      return _foldInterpolation(node, optimization);
    }
    if (node is GroupExpr) {
      return fold(node.inner, optimization);
    }
    if (node is IdentifierExpr) {
      return _foldIdentifier(node, optimization);
    }
    if (node is UnaryPrefixExpr) {
      return _foldUnary(node, optimization);
    }
    if (node is BinaryExpr) {
      return _foldBinary(node, optimization);
    }
    if (node is TernaryExpr) {
      final condition = fold(node.condition, optimization);
      if (condition?.value is! bool) return null;
      return condition!.value as bool
          ? fold(node.thenBranch, optimization)
          : fold(node.elseBranch, optimization);
    }
    return null;
  }

  HTConstantValue? _foldIdentifier(
    IdentifierExpr node,
    HTOptimizationResult optimization,
  ) {
    final reference = optimization.references[node];
    if (reference == null || reference.storage == HTResolvedStorage.dynamic) {
      return null;
    }
    final declaration = reference.variable.declaration;
    if (declaration is! VarDecl ||
        !declaration.isConst ||
        declaration.initializer == null ||
        declaration.lateFinalize ||
        declaration.isExternal) {
      return null;
    }
    if (!_visitingDeclarations.add(declaration)) return null;
    final result = fold(declaration.initializer!, optimization);
    _visitingDeclarations.remove(declaration);
    return result;
  }

  HTConstantValue? _foldUnary(
    UnaryPrefixExpr node,
    HTOptimizationResult optimization,
  ) {
    final operand = fold(node.object, optimization);
    if (operand == null) return null;
    final value = operand.value;
    try {
      if (node.op == _lexicon.logicalNot && value is bool) {
        return HTConstantValue(!value);
      }
      if (node.op == _lexicon.negative && value is num) {
        return HTConstantValue(-value);
      }
      if (node.op == _lexicon.bitwiseNot && value is int) {
        return HTConstantValue(~value);
      }
    } on Object {
      return null;
    }
    return null;
  }

  HTConstantValue? _foldBinary(
    BinaryExpr node,
    HTOptimizationResult optimization,
  ) {
    if (node.op == _lexicon.logicalAnd) {
      final left = fold(node.left, optimization);
      if (left?.value is! bool) return null;
      if (!(left!.value as bool)) return const HTConstantValue(false);
      final right = fold(node.right, optimization);
      return right?.value is bool ? right : null;
    }
    if (node.op == _lexicon.logicalOr) {
      final left = fold(node.left, optimization);
      if (left?.value is! bool) return null;
      if (left!.value as bool) return const HTConstantValue(true);
      final right = fold(node.right, optimization);
      return right?.value is bool ? right : null;
    }
    if (node.op == _lexicon.ifNull) {
      final left = fold(node.left, optimization);
      if (left != null) return left;
      return null;
    }

    final left = fold(node.left, optimization);
    final right = fold(node.right, optimization);
    if (left == null || right == null) return null;
    final leftValue = left.value;
    final rightValue = right.value;
    try {
      if (node.op == _lexicon.add) {
        if (leftValue is String && rightValue is String) {
          return HTConstantValue(leftValue + rightValue);
        }
        if (leftValue is num && rightValue is num) {
          return HTConstantValue(leftValue + rightValue);
        }
      } else if (node.op == _lexicon.subtract &&
          leftValue is num &&
          rightValue is num) {
        return HTConstantValue(leftValue - rightValue);
      } else if (node.op == _lexicon.multiply &&
          leftValue is num &&
          rightValue is num) {
        return HTConstantValue(leftValue * rightValue);
      } else if (node.op == _lexicon.devide &&
          leftValue is num &&
          rightValue is num &&
          rightValue != 0) {
        return HTConstantValue(leftValue / rightValue);
      } else if (node.op == _lexicon.truncatingDevide &&
          leftValue is num &&
          rightValue is num &&
          rightValue != 0) {
        return HTConstantValue(leftValue ~/ rightValue);
      } else if (node.op == _lexicon.modulo &&
          leftValue is num &&
          rightValue is num &&
          rightValue != 0) {
        return HTConstantValue(leftValue % rightValue);
      } else if (node.op == _lexicon.lesser &&
          leftValue is num &&
          rightValue is num) {
        return HTConstantValue(leftValue < rightValue);
      } else if (node.op == _lexicon.lesserOrEqual &&
          leftValue is num &&
          rightValue is num) {
        return HTConstantValue(leftValue <= rightValue);
      } else if (node.op == _lexicon.greater &&
          leftValue is num &&
          rightValue is num) {
        return HTConstantValue(leftValue > rightValue);
      } else if (node.op == _lexicon.greaterOrEqual &&
          leftValue is num &&
          rightValue is num) {
        return HTConstantValue(leftValue >= rightValue);
      } else if (node.op == _lexicon.equal) {
        return HTConstantValue(leftValue == rightValue);
      } else if (node.op == _lexicon.notEqual) {
        return HTConstantValue(leftValue != rightValue);
      } else if (node.op == _lexicon.bitwiseOr &&
          leftValue is int &&
          rightValue is int) {
        return HTConstantValue(leftValue | rightValue);
      } else if (node.op == _lexicon.bitwiseXor &&
          leftValue is int &&
          rightValue is int) {
        return HTConstantValue(leftValue ^ rightValue);
      } else if (node.op == _lexicon.bitwiseAnd &&
          leftValue is int &&
          rightValue is int) {
        return HTConstantValue(leftValue & rightValue);
      } else if (node.op == _lexicon.leftShift &&
          leftValue is int &&
          rightValue is int) {
        return HTConstantValue(leftValue << rightValue);
      } else if (node.op == _lexicon.rightShift &&
          leftValue is int &&
          rightValue is int) {
        return HTConstantValue(leftValue >> rightValue);
      } else if (node.op == _lexicon.unsignedRightShift &&
          leftValue is int &&
          rightValue is int) {
        return HTConstantValue(leftValue >>> rightValue);
      }
    } on Object {
      return null;
    }
    return null;
  }

  HTConstantValue? _foldInterpolation(
    ASTStringInterpolation node,
    HTOptimizationResult optimization,
  ) {
    final interpolations = <String>[];
    for (final expression in node.interpolations) {
      final value = fold(expression, optimization);
      if (value == null) return null;
      interpolations.add(_lexicon.stringify(value.value));
    }
    var text = node.text;
    for (var i = 0; i < interpolations.length; ++i) {
      text = text.replaceAll(
        '${_lexicon.stringInterpolationStart}$i${_lexicon.stringInterpolationEnd}',
        interpolations[i],
      );
    }
    return HTConstantValue(_escape(text));
  }

  String _escape(String value) {
    var result = value;
    _lexicon.escapeCharacters.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }
}
