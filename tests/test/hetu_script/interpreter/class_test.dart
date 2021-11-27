import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();
  hetu.init();

  group('classes -', () {
    test('named constructor', () {
      final result = hetu.eval(r'''
        class AGuy {
          var name
          construct withName (name: str) {
            this.name = name
          }
        }
        fun namedConstructor {
          var p = AGuy.withName('harry')
          return p.name
        }
      ''', invokeFunc: 'namedConstructor');
      expect(
        result,
        'harry',
      );
    });
    test('static member', () {
      final result = hetu.eval('''
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
          var a = StaticField('yellow')
          a.b()
          return StaticField.field
        }
      ''', invokeFunc: 'getStatic');
      expect(
        result,
        'yellow',
      );
    });

    test('override', () {
      final result = hetu.eval('''
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
      fun overrideTest {
        var j = John()
        return j.meaning();
      }
      ''', invokeFunc: 'overrideTest');
      expect(
        result,
        42,
      );
    });

    test('inherits', () {
      final result = hetu.eval('''
      class Super1 {
        var name = 'Super'
        var age = 1
        fun addAge() {
          age = age + 1
        }
      }
      class Extend1 extends Super1 {
        var name = 'Extend'
        fun addAge() {
          age = age + 1
          super.addAge()
        }
      }
      fun inherits {
        var a = Extend1()
        a.addAge()
        return a.age
      }
      ''', invokeFunc: 'inherits');
      expect(
        result,
        3,
      );
    });
    test('type cast', () {
      final result = hetu.eval(r'''
        class Super3 {
          var name = 'Super'
        }
        class Extend3 extends Super3 {
          var name = 'Extend'
        }
        fun superMember {
          var a = Extend3()
          var b = a as Super3
          b.name = 'changed'
          return (a as Super3).name
        }
      ''', invokeFunc: 'superMember');
      expect(
        result,
        'changed',
      );
    });
    test('derived sequence', () {
      final result = hetu.eval(r'''
        class SuperC1 {
          var name
          construct (name) {
            this.name = name
          }
        }
        class DerivedC1 extends SuperC1 {
          construct: super('Derived') {
            name += 'Sequence'
          }
        }
        fun cotrSequence {
          var d = DerivedC1()
          return d.name
        }
      ''', invokeFunc: 'cotrSequence');
      expect(
        result,
        'DerivedSequence',
      );
    });
    test('factory constructor', () {
      final result = hetu.eval(r'''
        class Choclate {
          factory Factory {
            return Choclate._('Choclate')
          }
          var name
          construct _(name) {
            this.name = name
          }
        }
        fun factoryCtor {
          var d = Choclate.Factory();
          return d.name
        }
      ''', invokeFunc: 'factoryCtor');
      expect(
        result,
        'Choclate',
      );
    });
    test('enum class', () {
      final result = hetu.eval(r'''
        enum Race {
          caucasian,
          mongolian,
          african,
        }
        fun enumTest {
          var race: Race = Race.african
          return race.toString()
        }
      ''', invokeFunc: 'enumTest');
      expect(
        result,
        'Race.african',
      );
    });
  });
}
