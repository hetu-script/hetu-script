import '../parser/token.dart' show TokenCommentOrEmptyLine;

enum CommentType {
  emptyLine,
  singleLine,
  multiLine,
  documentation,
}

/// Comment or Empty line before a statement.
class CommentOrEmptyLine {
  final String content;

  final CommentType type;

  final bool isTrailing;

  CommentOrEmptyLine(
      {required this.content, required this.type, this.isTrailing = false});

  CommentOrEmptyLine.fromCommentToken(TokenCommentOrEmptyLine token)
      : this(
            content: token.literal,
            type: token.commentType,
            isTrailing: token.isTrailing);
}
