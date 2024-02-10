import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu(
    config: HetuConfig(
      printPerformanceStatistics: false,
    ),
  );
  hetu.init();

  group('classes -', () {
    test('named constructor', () {
      final result = hetu.eval(r'''
        class AGuy {
          var name
          constructor withName (name: str) {
            this.name = name
          }
        }
        var p = AGuy.withName('harry')
        p.name
      ''');
      expect(
        result,
        'harry',
      );
    });
    test('static member', () {
      final result = hetu.eval(r'''
        class StaticField {
          static var field: str
          constructor ([field: str = 'a']) {
            StaticField.field = field
          }
          static function a {
            return field
          }
          function b {
            a()
          }
        }
        var a = StaticField('yellow')
        a.b()
        StaticField.field
      ''');
      expect(
        result,
        'yellow',
      );
    });

    test('override', () {
      final result = hetu.eval(r'''
        class Guy {
          function meaning {
            return null
          }
        }
        class John extends Guy {
          get number { return 42 }
          function meaning {
            return number
          }
        }
        var j = John()
        j.meaning();
      ''');
      expect(
        result,
        42,
      );
    });

    test('inherits', () {
      final result = hetu.eval(r'''
        class Super1 {
          var name = 'Super'
          var age = 1
          function addAge() {
            age = age + 1
          }
        }
        class Extend1 extends Super1 {
          var name = 'Extend'
          function addAge() {
            age = age + 1
            super.addAge()
          }
        }
        var a = Extend1()
        a.addAge()
        a.age
      ''');
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
        var a = Extend3()
        var b = a as Super3
        b.name = 'changed'
        (a as Super3).name
      ''');
      expect(
        result,
        'changed',
      );
    });
    test('derived sequence', () {
      final result = hetu.eval(r'''
        class SuperC1 {
          var name
          constructor (name) {
            this.name = name
          }
        }
        class DerivedC1 extends SuperC1 {
          constructor: super('Derived') {
            name += 'Sequence'
          }
        }
        var d = DerivedC1()
        d.name
      ''');
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
          constructor _(name) {
            this.name = name
          }
        }
        var d = Choclate.Factory();
        d.name
      ''');
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
        var race: Race = Race.african
        race.toString()
      ''');
      expect(
        result,
        'Race.african',
      );
    });
  });
}
