import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();

  group('buildin values -', () {
    test('string interpolation', () async {
      final result = await hetu.eval(r'''
      fun interpolation {
        var a = 'dragon'
        return ('To kill the ${a}, you have to wait ${6*7} years.')
      }
    ''', invokeFunc: 'interpolation');
      expect(
        result,
        'To kill the dragon, you have to wait 42 years.',
      );
    });
  });

  group('operators -', () {
    test('ternary operator', () async {
      final result = await hetu.eval(r'''
      fun tenary {
       return ((5 > 4 ? true ? 'certainly' : 'yeah' : 'ha') + ', eva!')
      }
    ''', invokeFunc: 'tenary');
      expect(
        result,
        'certainly, eva!',
      );
    });
  });

  group('control flow -', () {
    test('loop', () async {
      final result = await hetu.eval(r'''
      fun loop {
        var j = 1
        var i = 0
        for (;;) {
          ++i
          when (i % 2) {
            0: j += i
            1: j *= i
          }
          if (i > 5) {
            break
          }
        }
        return j
      }
    ''', invokeFunc: 'loop');
      expect(
        result,
        71,
      );
    });

    test('for in', () async {
      final result = await hetu.eval(r'''
      fun forIn() { 
        var rows = [1, 2, 3]
        var r = 1
        for (var attr in rows) {
          var p = attr * attr
          r += p
        } 
        return r
      }
    ''', invokeFunc: 'forIn');
      expect(
        result,
        15,
      );
    });
  });

  group('variables -', () {
    test('global var', () async {
      final result = await hetu.eval(r'''
      var globalVar = 0
      class GetGlobal {
        construct {
          globalVar = 2
        }
        fun test {
          return (globalVar * globalVar)
        }
        static fun staticTest {
          return (globalVar + 1)
        }
      }
      fun getGlobalVar() {
        var a = GetGlobal()
        return a.test() + GetGlobal.staticTest()
      }
    ''', invokeFunc: 'getGlobalVar');
      expect(
        result,
        7,
      );
    });
  });

  group('functions -', () {
    test('closure', () async {
      final result = await hetu.eval('''
            fun literalFunction(func) {
              var i = 42
              fun nested () {
                i = i + 1
                return (func(i))
              }
              return nested
            }
            fun closure {
              var func = literalFunction( fun (n) => n * n )
              func()
              return func()
            }
      ''', invokeFunc: 'closure');
      expect(
        result,
        1936,
      );
    });
  });

  group('classes -', () {
    test('static member', () async {
      final result = await hetu.eval('''
        class StaticField {
          static var field: str
          construct ([field: str = 'a']) {
            StaticField.field = field
          }
          static fun a {
            return field
          }
          fun b {
            a()
          }
        }
        fun getStatic {
          var a = StaticField()
          a.b()
        }
      ''', invokeFunc: 'getStatic');
      expect(
        result,
        'a',
      );
    });

    test('inheritance', () async {
      final result = await hetu.eval('''
      class Guy {
        fun meaning {
          return null
        }
      }
      class John extends Guy {
        get number { return 42 }
        fun meaning {
          return number
        }
      }
      fun inheritance {
        var j = John()
        return j.meaning();
      }
      ''', invokeFunc: 'inheritance');
      expect(
        result,
        42,
      );
    });
  });

  group('import handler -', () {
    test('import', () async {
      final result = await hetu.import('script/import_test.ht', debugMode: false, invokeFunc: 'importTest');
      expect(
        result,
        87.5,
      );
    });
  });

  group('edge cases -', () {
    test('automatic semicolon insertion', () async {
      final result = await hetu.eval(r'''
        fun asi {
          var j = 3
          var i =
            ('all' 
            + 'oha')
          ++j
          if (i is num)
        return
            return j
        }

  ''', invokeFunc: 'asi');
      expect(
        result,
        4,
      );
    });

    test('late initialization', () async {
      final result = await hetu.eval(r'''
      fun getIndex {
        return 2
      }
      fun lateInit {
        var tables = { 'weapon': [1,2,3] }
        var rows = tables['weapon'];
        var i = getIndex()
        return rows[i]
      }
  ''', invokeFunc: 'lateInit');
      expect(
        result,
        3,
      );
    });

    test('var in lambda', () async {
      final result = await hetu.eval(r'''
        class Left {
          var age = 10
          fun m() {
            var b = Right(fun(n) {
              age = n
            })
            b.exec()
          }
        }
        class Right {
          var f
          construct(f) {
            this.f = f
          }
          fun exec () {
            f(5)
          }
        }
        fun lambdaVar() {
          var a = Left()
          a.m()
          return a.age
        }
  ''', invokeFunc: 'lambdaVar');
      expect(
        result,
        5,
      );
    });
  });
}
