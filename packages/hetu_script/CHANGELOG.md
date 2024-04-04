## 0.6.0

- Add bitwise operators and bitwise shifts operators.
- Redo crypto/console/Math/JSON related api to make them more similar to Javascript.

## 0.5.0

- Add experimental support for async/await.

## 0.4.3

- Add help() api for get the documentation comments content of a certain identifier.
- Add clone() api on List for deepcopy a list.

## 0.4.1

- Add api for dynamically import a source: `final { a, b } = require(path)`
- Add Future() constructor.
- Add static value() & wait() methods on Future class binding.
- Add async keyword for declaration a async function.
- Add fundations for support const expression interpreter and static analyzer (still WIP).
- Add suport for multiline String literal, syntax is the same to normal string.
- Add support for user-defined lexicon & parser, you can define a language with
  custom lexicon & grammar that compiles into the bytecode and runs with Hetu.
- Add this syntax in constructor's parameter list to quick initialize a instance member on class or named struct.
- Named arguments can be placed anywhere in the function call arguments list, just like in Dart 2.17.
- ** BREAKING CHANGE **:
  Bytecode has changes so the bytecode module compiled by earlier version is not compatible for this version.
  SDK dependency has UPGRADE to Dart 2.17.
  Changed Math.random() related api to separated Random class binding (this is for support of random seed).

## 0.3.12

- Added destructuring declaration: 'var { a, b } = { a: 1, b: 2 }; var [ _, x, y ] = [ 1, 2, 3 ]'.
- Added '\_' syntax to omit function parameters or to omit positional value in destructuring declarations.
- Added 'throw' statement to throw a error within the script. (It has to be handled within Dart code).
- Added import syntax for pre-compiled binary module. "import 'module:module-name'".

## 0.3.11

- You can now directly use operator '[]' & '[]=' on HTStruct object like a Map in Dart code.
- Changed range(start, end, [step]) to range(end, [start, step]), make it even simpler to use.
- Add api randomColorHex(), randomBool() on Math class.
- Add string.characters Iterable api for iterating through Strings.
- Add toPercentageString() on number.

## 0.3.10

- Added 'range(a, b)', 'List.random', 'eval(code)', 'Math.radiusToSigma(radius)', 'Math.gaussianNoise(mean, variance)', 'Hash.uid4()', 'Hash.crc32b(data)' apis.
- Added Dart Set & Iterable, Iterator support.
- Added 'x in Iterable' boolean expression.
- Added interface typealias and runtime type check on struct literal.
- Added Function.apply() method on struct literal.
- When statement's cases now support advance usage including multiple value (comma expression) and in/of expression.

## 0.3.8

- Add variable shadowing.
- Add 'delete' keyword, works on local variable or struct field.

## 0.3.7

- Add namespace declaration statement.
- Now can directly import a JSON file into code. It will become a HTStruct object.

## 0.3.6

- Due to web support compatibility reasons, changed internal integer bytecode from 64bit to 32bit.
- Added BigInt builtin binding.

## 0.3.5

- Added const declaration for boolean, int, float and string.
- Fixed comment parsing problems. Now comment could be written almost anywhere without affect parser.

## 0.3.4

- Added for...of syntax for iterate through values of Map or struct literal.
- When statement now can also be used as expression.
- If null syntax: '?.', '??', '??='.

## 0.3.3

- Added spread syntax on function call argument, list and struct literal
- Added short identifier for struct literal

## 0.3.2

- Added [isStrictMode] for interpreter, in non strict mode, if/while/do and and/or expression can have a non boolean value for condition check.
- Added Future.then external method for script to handle with Dart Futures.

## 0.3.1

- **Changed the external function typedef in Dart, added namespace as first arg when called.**

## 0.3.0

- Command line tool and file system context support moved to another package: [hetu_script_dev_tools].
- Added a new kind of external binding: external method on normal classes
- Added support for literal function expression with no keyword.
- Added struct literal and prototype based object system. **The map literal is replaced with struct literal.**

## 0.2.0

- Analyzer can check for syntactic errors now.
- Added IDE support for analyzer and formatter.
- Compile source into bytecode and load it at another time to skip parsing and compile process.

## 0.1.3

- Named constructor can refer to default constructor: 'constructor name(): this()'.
- Feature: Single expression 'function: function add(a, b) => a + b'.
- Feature: Type alias: 'type MyFuncType = function (number, number) -> number'.

## 0.1.2

- Added Analyzer and Formatter utility classes (WIP).
- Added Type expression and related assignment operations.
- Feature: Added default implementation of 'toJSON' on instances.

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
- Feature: Full support on While, Do loops, classic for(init;condition;increment), for...in, when statement (works like switch).
- Feature: Ternary operator: 'conditon ? true : false'.
- Feature: Interpreter function for bind Dart Function Typedef.

## 0.0.5

- Refactor: Migrate to null safety.
- Feature: Literal function expression (anonymous function).
- Feature: Named function parameters.
- Feature: Support literal hexadecimal numbers.

## 0.0.1

- Initial version, hello world!
