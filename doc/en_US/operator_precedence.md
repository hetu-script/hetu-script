## Hetu operator precedence

| Description    | Operator               | Associativity | Precedence |
| :------------- | :--------------------- | :-----------: | :--------: |
| Unary postfix  | e., e(), e[], e++, e-- |     None      |     16     |
| Unary prefix   | -e, !e, ++e, --e       |     None      |     15     |
| Multiplicative | \*, /, %               |     Left      |     14     |
| Additive       | +, -                   |     Left      |     13     |
| Relational     | <, >, <=, >=, is, is!  |     None      |     8      |
| Equality       | ==, !=                 |     None      |     7      |
| Logical AND    | &&                     |     Left      |     6      |
| Logical Or     | \|\|                   |     Left      |     5      |
| Conditional    | e1 ? e2 : e3           |     Right     |     3      |
| Assignment     | =, \*=, /=, +=, -=     |     Right     |     1      |

## Dart operator precedence (for reference)

| Description    | Operator                         | Associativity | Precedence |
| :------------- | :------------------------------- | :-----------: | :--------: |
| Unary postfix  | e., e?., e++, e--, e1[e2], e()   |     None      |     16     |
| Unary prefix   | -e, !e, ˜e, ++e, --e, await e    |     None      |     15     |
| Multiplicative | \*, /, ˜/, %                     |     Left      |     14     |
| Additive       | +, -                             |     Left      |     13     |
| Shift          | <<, >>, >>>                      |     Left      |     12     |
| Bitwise        | AND &                            |     Left      |     11     |
| Bitwise        | XOR ˆ                            |     Left      |     10     |
| Bitwise        | OR \|                            |     Left      |     9      |
| Relational     | <, >, <=, >=, as, is, is!        |     None      |     8      |
| Equality       | ==, !=                           |     None      |     7      |
| Logical        | and &&                           |     Left      |     6      |
| Logical        | or \|\|                          |     Left      |     5      |
| If-null        | ??                               |     Left      |     4      |
| Conditional    | e1 ? e2 : e3                     |     Right     |     3      |
| Cascade        | ..                               |     Left      |     2      |
| Assignment     | =, \*=, /=, +=, -=, &=, ˆ=, etc. |     Right     |     1      |
