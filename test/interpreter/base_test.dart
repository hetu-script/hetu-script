import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();

  group('buildin values -', () {
    test('string interpolation', () {
      final result = hetu.eval(r'''
      fun interpolation {
        var a = 'dragon'
        var b
        return ('To kill the ${a}, you have to wait ${b} years.')
      }
    ''', invokeFunc: 'interpolation');
      expect(
        result,
        'To kill the dragon, you have to wait null years.',
      );
    });
  });

  group('operators -', () {
    test('brackets', () {
      final result = hetu.eval(r'''
      fun math1 { 
        return 3 - (2 * 3 - 5)
      }
    ''', invokeFunc: 'math1');
      expect(
        result,
        2,
      );
    });
    test('ternary operator', () {
      final result = hetu.eval(r'''
      fun ternary {
       return ((5 > 4 ? true ? 'certainly' : 'yeah' : 'ha') + ', eva!')
      }
    ''', invokeFunc: 'ternary');
      expect(
        result,
        'certainly, eva!',
      );
    });
    test('member and sub get', () {
      final result = hetu.eval(r'''
        class Ming {
          var first = 'tom'
        }
        class Member {
          var array = {'tom': 'kaine'}
          var name = Ming()
        }
        fun subGet() {
          var m = Member()
          return m.array[m.name.first]
        }
    ''', invokeFunc: 'subGet');
      expect(
        result,
        'kaine',
      );
    });
  });

  group('control flow -', () {
    test('loop', () {
      final result = hetu.eval(r'''
      fun loop {
        var j = 1
        var i = 0
        for (;;) {
          ++i
          when (i % 2) {
            0 -> j += i
            1 -> j *= i
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
    test('for in', () {
      final result = hetu.eval(r'''
      fun forIn {
        let value = ['', 'hello', 'world']
        let item = ''
        for (let val in value) {
          if (val != '') {
            item = val
            break
          }
        }
        return item
      }
    ''', invokeFunc: 'forIn');
      expect(
        result,
        'hello',
      );
    });
    test('continue', () {
      final result = hetu.eval(r'''
      fun continueLoop {
        var j = 0
        for (var i = 0; i < 5; ++i) {
          if (i % 2 == 0){
            continue
          }
          j += i
        }
        return j
      }
    ''', invokeFunc: 'continueLoop');
      expect(
        result,
        4,
      );
    });
    test('when', () {
      final result = hetu.eval(r'''
        fun swtich(expr) {
          when(expr) {
            0-> return '0'
            1-> return '1'
          }
          return ''
        }
        fun whenStmt {
          return swtich(5 - 4)
        }
    ''', invokeFunc: 'whenStmt');
      expect(
        result,
        '1',
      );
    });
  });

  group('variables -', () {
    test('global var', () {
      final result = hetu.eval(r'''
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
}
