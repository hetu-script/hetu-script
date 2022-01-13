# Common API

## API for dart code

### Interpreter

The most common class you will be using is the Interpreter, it is named as 'Hetu' in this library.

#### init()

This method is a convenient way to load some shared modules together before you can use them.

- **preincludes**: Hetu source in String literal form. You can also use **eval** methods to load them later.
- **externalFunctions**: Dart functions to be binded with a external function declaration in Hetu. You can also use **bindExternalFunction** methods to load them later.
- **HTExternalFunctionTypedef**: Dart typedefs to be used when a Hetu function want to be converted to a Dart function when evaluated. You can also use **bindExternalFunctionType** methods to load them later.
- **HTExternalClass**: Dart class bindings to be used by Hetu to get class definitions. You can also use **bindExternalClass** methods to load them later.

```dart
void init({
  Map<String, String> includes = const {},
  Map<String, Function> externalFunctions = const {},
  Map<String, HTExternalFunctionTypedef> externalFunctionTypedef = const {},
  List<HTExternalClass> externalClasses = const ****,
})
```

#### eval()

To parse, analyze, compile and load a Hetu source from a String literal.

```dart
dynamic eval(String content,
    {String? fileName,
    String? moduleName,
    bool globallyImport = false,
    ResourceType type = ResourceType.hetuLiteralCode,
    bool isStrictMode = false,
    String? invokeFunc,
    List<dynamic> positionalArgs = const ****,
    Map<String, dynamic> namedArgs = const {},
    List<HTType> typeArgs = const ****,
    bool errorHandled = false})
```

- **content**: Hetu source as String literal.
- **fileName**: The name of this source, it will be used when other source try to import from it.
- **moduleName**: The name of the compilation result, i.e. the program or library's name.
- **globallyImport**: Whether you want the content of this source is visible to **global** namespace. It's a quicker way to let other modules to use without import statement.
- **type**: How the interpreter evaluate this source. For more information, check [**source type**](../module/readme.md#Source-type).
- **isStrictMode**: If strict mode is true, the condition expression used by if/while/do/ternery must be a boolean value. Otherwise there will be inexplicit type conversion.
- **invokeFunc**: Invoke a function immediately after evaluation. The function's name and parameter can be of any form. The arguments of this function call are provided by **positionalArgs** and **namedArgs**. You can also use the separate method **invoke** to do the same thing.

#### compile(), loadBytecode()

These methods is useful if you wish for more efficient runtime of the script. You can compile a source into bytecode. And run it at another time so that the interpreter will skip the parsing, analyzing and compiling process.

If you would like to compile and store the result as physical files. You can check **command line tool**(../command_line_tool/readme.md#compile) in the hetu_script_dev_tools package.

### Invoke a method on Hetu object

Besides the **invoke** method on interpreter, you can also use the same named methods on **HTClass** and **HTInstance** and **call** on **HTFunction**, if you have those object passed from script into the Dart.

### ResourceContext

If you installed 'hetu_script_dev_tools' or 'hetu_script_flutter', they will handle the source context for you so you won't need to add the source file into the context manually. However if you cannot use these packages(for example if your code are on web browser), you can use methods below on **HTOverlayContext** to manage sources.

```dart
void addResource(String fullName, HTSource resource)

void removeResource(String fullName)

void updateResource(String fullName, HTSource resource)
```

## API for script code

### Preincluded values

Most of the preincluded values' apis are named based on Dart SDK's Classes:
**num**, **int**, **double**, **bool**, **String**, **List**, **Set** and **Map**

There are also some hetu exclusive methods, like **List.random**, to get a random item out of a List.

### Core functions

```javascript
external fun print(... args: any)

external fun stringify(obj: any)

external fun jsonify(obj)

fun range(min: int, max: int)
```

### object & struct

````typescript

struct prototype {
  /// Create a struct from a dart Json data
  /// Usage:
  /// ```
  /// var obj = prototype.fromJson(jsonDataFromDart)
  /// ```
  external static fun fromJson(data) -> {}

  /// Get the List of the keys of this struct
  external get keys -> List

  /// Get the List of the values of this struct
  /// The values are copied,
  /// you cannot modify the struct in this way
  external get values -> List

  /// Check if this struct has a key in its own fields.
  external fun owns(key: str) -> bool

  /// Check if this struct has a key
  /// in its own fields or its prototypes' fields.
  external fun contains(key: str) -> bool

  /// Check if this struct is empty.
	external get isEmpty -> bool

  /// Check if this struct is not empty.
	external get isNotEmpty -> bool

  /// Get the number of the members of this struct.
  /// Will not include the members of its prototypes.
	external get length -> int

  /// Create a new struct form deepcopying this struct
  external fun clone() -> {}

  /// Create dart Json data from this struct
  fun toJson() -> Map => jsonify(this)

  fun toString() -> str => stringify(this)
}
````

### Math

```javascript
external class Math {
  static const e: num = 2.718281828459045

  static const pi: num = 3.1415926535897932external

  static fun radiusToSigma(radius: float) -> float

  // Box–Muller transform for generating normally distributed random numbers
  static fun gaussianNoise(mean: float, variance: float) -> float

  // Compute Perlin noise at coordinates x, y
  static fun perlinNoise(x: float, y: float) -> float

  static fun min(a, b)

  static fun max(a, b)

  static fun random() -> num

  static fun randomInt(max: num) -> num

  static fun sqrt(x: num) -> num

  static fun pow(x: num, exponent: num) -> num

  static fun sin(x: num) -> num

  static fun cos(x: num) -> num

  static fun tan(x: num) -> num

  static fun exp(x: num) -> num

  static fun log(x: num) -> num

  static fun parseInt(source: str, {radix: int?}) -> num

  static fun parseDouble(source: str) -> num

  static fun sum(list: List<num>) -> num

  static fun checkBit(index: num, check: num) -> bool

  static fun bitLS(x: num, distance: num) -> bool

  static fun bitRS(x: num, distance: num) -> bool

  static fun bitAnd(x: num, y: num) -> bool

  static fun bitOr(x: num, y: num) -> bool

  static fun bitNot(x: num) -> bool

  static fun bitXor(x: num, y: num) -> bool
}
```

### Hash

```javascript
external class Hash {

  static fun uid4(repeat: int) -> str

  static fun crc32b(data: str, [crc: str = 0]) -> str
}
```
