/// The core librarys in Hetu.
///
/// Automatically generated based on files in 'hetu_lib' folder.
final Map<String, String> coreLibs = const {
'core.ht': r'''class Object {}

// return the runtime type of a value
external fun typeof(value): String

// return the declaration type of a symbol
// external fun decltypeof(value): String

external fun _print(items: List<any>)

// print values of any type into lines
fun print(... items) {
  _print(items)
}

external fun _string(items: List<any>): String

// concact values of any type into string
external fun string(... items): String{
  return _string(items)
}''',
'value.ht': r'''external class num {

	static fun parse(value): num

  fun toStringAsFixed([fractionDigits: num = 0]): num

  fun truncate(): num
}

external class bool {

	static fun parse(value): bool
}

external class String {

	static fun parse(value): String

	get isEmpty: bool

	get isNotEmpty: bool

	fun substring(startIndex: num, [endIndex: num]): String
}

external class List {

	get length: num

	get isEmpty: bool

	get isNotEmpty: bool

	fun add(value: dynamic)

	fun clear()

	fun removeAt(index: num)

	fun indexOf(value): num

	fun elementAt(index: num): any

	get first

	get last

	fun contains(value): bool
}

external class Map {

	get length: num

	get isEmpty: bool

	get isNotEmpty: bool

  get keys: List

  get values: List

	fun containsKey(value): bool

	fun containsValue(value): bool

	fun addAll(other: Map)

	fun clear()

	fun remove(key)

  fun putIfAbsent(key, value): any
}''',
'system.ht': r'''external class System {
  // invoke a global or static member function
  static fun invoke(functionName: String, {positionalArgs: List = [], namedArgs: Map<String> = {}})

  static get now: num

  // static fun tik()

  // static fun tok()
}''',
'console.ht': r'''external class Console {

	// write a line without return
	static fun write(line: String)
	
	// write a line ends with return
	static fun writeln(line: String)
	
	static fun getln(info: String): String
	
	static fun eraseLine()
	
	static fun setTitle(title: String)
	
	static fun cls()
}''',
'math.ht': r'''fun max(a: num, b: num): num {
  if (a > b) return a
  return b
}

fun min(a: num, b: num): num {
  if (a < b) return a
  return b
}

fun abs(x: num): num {
  if (x < 0) return -x
  return x
}

external fun random(): num

external fun randomInt(max: num): num

external fun sqrt(x: num): num

external fun log(x: num): num

external fun sin(x: num): num

external fun cos(x: num): num
''',
'help.ht': r'''external fun help(value): String''',
};
