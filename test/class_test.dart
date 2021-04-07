import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();

  group('classes -', () {
    test('named constructor', () async {
      final result = await hetu.eval(r'''
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
          var a = StaticField('yellow')
          a.b()
        }
      ''', invokeFunc: 'getStatic');
      expect(
        result,
        'yellow',
      );
    });

    test('override', () async {
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
      fun override {
        var j = John()
        return j.meaning();
      }
      ''', invokeFunc: 'override');
      expect(
        result,
        42,
      );
    });

    test('inherits', () async {
      final result = await hetu.eval('''
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
    test('type cast', () async {
      final result = await hetu.eval(r'''
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
    test('derived sequence', () async {
      final result = await hetu.eval(r'''
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
  });
}
