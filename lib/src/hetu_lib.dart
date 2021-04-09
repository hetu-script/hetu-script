/// The pre-packaged modules of Hetu scripting language.
///
/// Automatically generated based on files in 'hetu_lib' folder.
final Map<String, String> coreModules = const {
      'core.ht': r'''class Object {

  // external get runtimeType -> Type

  // external fun toString -> str
}

// return the declaration type of a symbol
// external fun decltypeof(value) -> str

// print values of any type into lines
external fun print(... args)''',
'value.ht': r'''/// The apis here are named based on Dart SDK's
/// [num], [int], [double], [bool], [String], [List] and [Map]

external class num {

	static fun parse(value: str) -> num

}

external class int extends num {
  /// Parse [source] as a, possibly signed, integer literal.
  static fun parse(source: str, {radix: int}) -> int
	
  /// Returns this integer to the power of [exponent] modulo [modulus].
  fun modPow(exponent: int, modulus: int) -> int

  /// Returns the modular multiplicative inverse of this integer
  fun modInverse(modulus: int) -> int

  /// Returns the greatest common divisor of this integer and [other].
  fun gcd(other: int) -> int

  /// Returns true if and only if this integer is even.
  get isEven -> bool

  /// Returns true if and only if this integer is odd.
  get isOdd -> bool

  /// Returns the minimum number of bits required to store this integer.
  get bitLength -> int
	
  /// Returns the least significant [width] bits of this integer as a
  /// non-negative number (i.e. unsigned representation).  The returned value has
  /// zeros in all bit positions higher than [width].
  fun toUnsigned(width: int) -> int
	
  /// Returns the least significant [width] bits of this integer, extending the
  /// highest retained bit to the sign.  This is the same as truncating the value
  /// to fit in [width] bits using an signed 2-s complement representation.  The
  /// returned value has the same bit value in all positions higher than [width].
  fun toSigned(width: int) -> int

  /// Returns the absolute value of this integer.
  fun abs() -> int

  /// Returns the sign of this integer.
  get sign -> int

  /// Returns `this`.
  fun round() -> int

  /// Returns `this`.
  fun floor() -> int

  /// Returns `this`.
  fun ceil() -> int

  /// Returns `this`.
  fun truncate() -> int

  /// Returns `this.toDouble()`.
  fun roundToDouble() -> float

  /// Returns `this.toDouble()`.
  fun floorToDouble() -> float

  /// Returns `this.toDouble()`.
  fun ceilToDouble() -> float

  /// Returns `this.toDouble()`.
  fun truncateToDouble() -> float
  
  /// Converts [this] to a string representation in the given [radix].
  fun toRadixString(radix: int) -> str
}

external class float extends num {
	
}

external class bool {

	static fun parse(value: str) -> bool
}

external class str {

	static fun parse(value) -> str

	get isEmpty -> bool

	get isNotEmpty -> bool

	fun substring(startIndex: num, [endIndex: num]) -> str

	fun startsWith(pattern: str, [index: num]) -> bool

	fun endsWith(other: str) -> bool

	fun indexOf(pattern: str, [start: num]) -> num

	fun lastIndexOf(pattern, [start: num]) -> num

	fun compareTo(other) -> num

	fun trim() -> str

	fun trimLeft() -> str

	fun trimRight() -> str

	fun padLeft(width: num, [padding: str]) -> str

	fun padRight(width: num, [padding: str]) -> str

	fun contains(other: str, [startIndex: num]) -> bool

	fun replaceFirst(from: str, to: str, [startIndex: num]) -> str

	fun replaceAll(from: str, replace: str) -> str

	fun replaceRange(start: num, end: num, replacement: str) -> str

	fun split(pattern: str) -> List

	fun toLowerCase() -> str

	fun toUpperCase() -> str
}

external class List {

	get length -> num

	get isEmpty -> bool

	get isNotEmpty -> bool

	get first

	get last

	fun contains(value) -> bool

	fun add(value)

	fun addAll(value: List)

	fun clear()

	fun removeAt(index: num)

	fun indexOf(value) -> num

	fun elementAt(index: num) -> any

	fun join(splitter: str) -> str
}

external class Map {

	get length -> num

	get isEmpty -> bool

	get isNotEmpty -> bool

  get keys -> List

  get values -> List

	fun containsKey(value) -> bool

	fun containsValue(value) -> bool

	fun addAll(other: Map)

	fun clear()

	fun remove(key)

  fun putIfAbsent(key, value) -> any
}''',
'system.ht': r'''external class System {

  static get now -> num

  // static fun tik()

  // static fun tok()
}''',
'console.ht': r'''external class Console {

	// write a line without return
	static fun write(line: str)
	
	// write a line ends with return
	static fun writeln(line: str)
	
	static fun getln(info: str) -> str
	
	static fun eraseLine()
	
	static fun setTitle(title: str)
	
	static fun cls()
}''',
'math.ht': r'''
external class Math {
  static const e: num = 2.718281828459045;
  
  static const pi: num = 3.1415926535897932;

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

  static fun parseInt(source: str, {int: radix}) -> num

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
''',
'help.ht': r'''external fun help(value) -> str''',
};
