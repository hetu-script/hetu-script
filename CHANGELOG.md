## 0.1.4

- Analyzer can check for syntactic errors now.

## 0.1.3

- Named constructor can refer to default constructor: construct name(): this()
- Feature: Single expression function: fun add(a, b) = a + b
- Feature: Type alias: type MyFuncType = fun (num, num) -> num

## 0.1.2

- Added Analyzer and Formatter utility classes (WIP).
- Added Type expression and related assignment operations.
- Feature: Added default implementation of 'toJson' on instances.

## 0.1.1

- Feature: Sequenced constructor calling through super classes.
- Feature: 'super' keyword with instance method, for calling super class method.
- Feature: 'as' & 'is' operator, with super class checking & casting.
- Feature: Full funtion type check with parameters and return type.

## 0.1.0

- Refactor: Changed default interpreter into bytecode machine.
- Feature: String interpolation.
- Feature: Now fully support nested function and literal function.
- Feature: Added ++, -- post and pre operators, and +=, -=, \*=, /= operators.
- Feature: Full support on While, Do loops, classic for(init;condition;increment),
  for...in, when statement (works like switch).
- Feature: Ternary operator: 'conditon ? true : false'.
- Feature: Interpreter function for bind Dart Function Typedef.

## 0.0.5

- Refactor: Migrate to null safety.
- Feature: Literal function expression (anonymous function).
- Feature: Named function parameters.
- Feature: Support literal hexadecimal numbers.

## 0.0.1

- Initial version, hello world!
