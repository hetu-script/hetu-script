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

    test('inheritance 1', () async {
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

    test('inheritance 2', () async {
      final result = await hetu.eval('''
      class SuperClass {
        var name = 'Super'
        var age = 1
        fun addAge() {
          age = age + 1
        }
      }
      class ExtendClass extends SuperClass {
        var name = 'Extend'
        fun addAge() {
          age = age + 1
          super.addAge()
        }
      }
      fun inherits {
        var a = ExtendClass()
        a.addAge()
        return a.age
      }
      ''', invokeFunc: 'inherits');
      expect(
        result,
        3,
      );
    });
    test('explicit super method calling', () async {
      final result = await hetu.eval(r'''
        fun superMethod {
          var a = ExtendClass()
          a.addAge()
          return a.age
        }
      ''', invokeFunc: 'superMethod');
      expect(
        result,
        3,
      );
    });
    test('extends check', () async {
      final result = await hetu.eval(r'''
        fun extendsCheck {
          var a = ExtendClass()
          return a is SuperClass
        }
      ''', invokeFunc: 'extendsCheck');
      expect(
        result,
        true,
      );
    });
    test('type cast', () async {
      final result = await hetu.eval(r'''
        fun superMember {
          var a = ExtendClass()
          var b = a as SuperClass
          b.name = 'changed super name'
          return a.name
        }
      ''', invokeFunc: 'superMember');
      expect(
        result,
        'Extend',
      );
    });
  });
}
