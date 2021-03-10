/// The core librarys in Hetu.
///
/// Automatically generated based on files in 'hetu_lib' folder.
final Map<String, String> coreLibs = const {
'core.ht': r'''class Object {}

// return the runtime type of a value
external fun typeof(value): String

// return the declaration type of a symbol
// external fun decltypeof(value): String

// print values of any type into lines
external fun print(... args)

// concact values of any type into string
external fun string(... args): String''',
'value.ht': r'''class Value {

  // external关键字表示函数体在host语言中定义
	external fun toString(): String

}

class num extends Value {

	external static fun parse(value): num

  external fun toStringAsFixed([fractionDigits: num = 0]): num

  external fun truncate(): num
}

class bool extends Value {

	static fun parse(value): bool {
    if (value is bool) {
      return value
    } else if (value is num) {
      if (value != 0) {
        return true
      } else {
        return false
      }
    } else if (value is String) {
      return value.isNotEmpty
    } else {
      if (value != null) {
        return true
      } else {
        return false
      }
    }
  }
}

class String extends Value {
	
	external get isEmpty: bool
	
	get isNotEmpty: bool {
		return !isEmpty
	}

	external fun substring(startIndex: num, [endIndex: num]): String

	external static fun parse(value): String
}

class List extends Value {
	
	external get length: num
	
	get isEmpty: bool {
		return length == 0
	}
	
	get isNotEmpty: bool {
		return length != 0
	}
	
	external fun add(... args)
	
	external fun clear()
	
	external fun removeAt(index: num)
	
	external fun indexOf(value): num
	
	external fun elementAt(index: num): any
	
	get first: any {
    if (length > 0){
      return elementAt(0)
    }
	}
	
	get last: any {
    if (length > 0){
      return elementAt(length - 1)
    }
  }
	
	fun contains(value): bool {
		return indexOf(value) != -1
	}
}

class Map extends Value {
	
	external get length: num
	
	get isEmpty: bool {
		return length == 0
	}
	
	get isNotEmpty: bool {
		return length != 0
	}

  external get keys: List

  external get values: List
	
	external fun containsKey(value): bool

	external fun containsValue(value): bool
	
	external fun setVal(key, value)
	
	external fun addAll(other: Map)
	
	external fun clear()
	
	external fun remove(key)
	
	external fun getVal(key): any

  external fun putIfAbsent(key, value): any
}''',
'system.ht': r'''class System {
  // invoke a global or static member function
  external static fun invoke(func_name: String, className: String, args: List)

  external static fun now(): num
}''',
'console.ht': r'''class Console {

	// write a line without return
	external static fun write(line: String)
	
	// write a line ends with return
	external static fun writeln(line: String)
	
	external static fun getln(info: String): String
	
	external static fun eraseLine()
	
	external static fun setTitle(title: String)
	
	external static fun cls()

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
