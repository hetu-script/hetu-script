// ignore_for_file: non_constant_identifier_names

import 'package:highlight/highlight_core.dart';

abstract class CommonModes {
  static final backslashEscape = Mode(begin: "\\\\[\\s\\S]", relevance: 0);
  static final stringMode = Mode(
      className: "string",
      variants: [
        Mode(begin: "'", end: "'", illegal: "\\n", contains: [backslashEscape]),
        Mode(
            begin: "\"",
            end: "\"",
            illegal: "\\n",
            contains: [backslashEscape]),
        Mode(begin: "`", end: "`", illegal: "\\n", contains: [backslashEscape])
      ],
      relevance: 0);
  static final cLineCommentMode =
      Mode(className: "comment", begin: "//", end: "\$");
  static final cBlockCommentMode =
      Mode(className: "comment", begin: "/\\*", end: "\\*/");
  static final number = Mode(
      className: "number",
      variants: [
        Mode(begin: "\\b(0[bB][01]+)n?"),
        Mode(begin: "\\b(0[oO][0-7]+)n?"),
        Mode(
            begin:
                "(-?)(\\b0[xX][a-fA-F0-9]+|(\\b\\d+(\\.\\d*)?|\\.\\d+)([eE][-+]?\\d+)?)n?")
      ],
      relevance: 0);
  static final title =
      Mode(className: "title", begin: "[a-zA-Z]\\w*", relevance: 0);
}

final hetuscript = Mode(refs: {
  '~contains~3~starts~contains~1~contains~5': CommonModes.number,
  '~contains~3~starts~contains~1':
      Mode(className: "subst", begin: "\\\$\\{", end: "\\}", keywords: {
    "keyword":
        "null true false void type import export from any unknown never var final const def delete typeof namespace class enum fun struct this super abstract override external static extends implements with construct factory get set async await break continue return for in of if else while do when is as",
    "literal": "true false null",
    "built_in":
        "object function bool num int str List Map prototype Math Future print stringify jsonify toJson toString keys values owns contains length fromJson clone"
  }, contains: [
    CommonModes.stringMode,
    Mode(ref: '~contains~3'),
    Mode(ref: '~contains~3~starts~contains~1~contains~5'),
  ]),
  '~contains~10~contains~2~contains~3':
      Mode(begin: "\\(", end: "\\)", keywords: {
    "keyword":
        "null true false void type import export from any unknown never var final const def delete typeof namespace class enum fun struct this super abstract override external static extends implements with construct factory get set async await break continue return for in of if else while do when is as",
    "literal": "true false null",
    "built_in":
        "object function bool num int str List Map prototype Math Future print stringify jsonify toJson toString keys values owns contains length fromJson clone"
  }, contains: [
    Mode(self: true),
    CommonModes.stringMode,
    CommonModes.number,
  ]),
  '~contains~10~contains~2': Mode(
      className: "params",
      begin: "\\(",
      end: "\\)",
      excludeBegin: true,
      excludeEnd: true,
      keywords: {
        "keyword":
            "null true false void type import export from any unknown never var final const def delete typeof namespace class enum fun struct this super abstract override external static extends implements with construct factory get set async await break continue return for in of if else while do when is as",
        "literal": "true false null",
        "built_in":
            "object function bool num int str List Map prototype Math Future print stringify jsonify toJson toString keys values owns contains length fromJson clone"
      },
      contains: [
        CommonModes.cLineCommentMode,
        CommonModes.cBlockCommentMode,
        Mode(ref: '~contains~10~contains~2~contains~3')
      ]),
}, aliases: [
  "ht"
], keywords: {
  "keyword":
      "null true false void type import export from any unknown never var final const def delete typeof namespace class enum fun struct this super abstract override external static extends implements with construct factory get set async await break continue return for in of if else while do when is as",
  "literal": "true false null",
  "built_in":
      "object function bool num int str List Map prototype Math Future print stringify jsonify toJson toString keys values owns contains length fromJson clone"
}, contains: [
  CommonModes.stringMode,
  CommonModes.cLineCommentMode,
  CommonModes.cBlockCommentMode,
  Mode(ref: '~contains~3~starts~contains~1~contains~5'),
  Mode(
      begin:
          "(!|!=|!==|%|%=|&|&&|&=|\\*|\\*=|\\+|\\+=|,|-|-=|/=|/|:|;|<<|<<=|<=|<|===|==|=|>>>=|>>=|>=|>>>|>>|>|\\?|\\[|\\{|\\(|\\^|\\^=|\\||\\|=|\\|\\||\\x7e|\\b(case|return|throw)\\b)\\s*",
      keywords: "return throw case",
      contains: [
        CommonModes.cLineCommentMode,
        CommonModes.cBlockCommentMode,
        Mode(
            className: "function",
            begin: "(\\(.*?\\)|[a-zA-Z]\\w*)\\s*=>",
            returnBegin: true,
            end: "\\s*=>",
            contains: [
              Mode(className: "params", variants: [
                Mode(begin: "[a-zA-Z]\\w*"),
                Mode(begin: "\\(\\s*\\)"),
                Mode(
                    begin: "\\(",
                    end: "\\)",
                    excludeBegin: true,
                    excludeEnd: true,
                    keywords: {
                      "keyword":
                          "null true false void type import export from any unknown never var final const def delete typeof namespace class enum fun struct this super abstract override external static extends implements with construct factory get set async await break continue return for in of if else while do when is as",
                      "literal": "true false null",
                      "built_in":
                          "object function bool num int str List Map prototype Math Future print stringify jsonify toJson toString keys values owns contains length fromJson clone"
                    },
                    contains: [
                      Mode(self: true),
                      CommonModes.cLineCommentMode,
                      CommonModes.cBlockCommentMode
                    ])
              ])
            ])
      ],
      relevance: 0),
  Mode(
      className: "function",
      beginKeywords: "fun",
      end: "[\\{;]",
      excludeEnd: true,
      keywords: {
        "keyword":
            "null true false void type import export from any unknown never var final const def delete typeof namespace class enum fun struct this super abstract override external static extends implements with construct factory get set async await break continue return for in of if else while do when is as",
        "literal": "true false null",
        "built_in":
            "object function bool num int str List Map prototype Math Future print stringify jsonify toJson toString keys values owns contains length fromJson clone"
      },
      contains: [
        Mode(self: true),
        Mode(
            className: "title",
            begin: "[A-Za-z\$_][0-9A-Za-z\$_]*",
            relevance: 0),
        Mode(ref: '~contains~10~contains~2')
      ],
      illegal: "%",
      relevance: 0),
  Mode(
      beginKeywords: "construct",
      end: "[\\{;]",
      excludeEnd: true,
      contains: [Mode(self: true), Mode(ref: '~contains~10~contains~2')]),
  Mode(begin: "\\\$[(.]"),
  Mode(begin: "\\.[a-zA-Z]\\w*", relevance: 0),
  Mode(ref: '~contains~10~contains~2~contains~3')
]);
