import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu(
    config: HetuConfig(
      allowVariableShadowing: true,
      printPerformanceStatistics: false,
    ),
  );
  hetu.init();

  group('getter -', () {
    test('instance getter returns computed value', () {
      final result = hetu.eval(r'''
        class Rectangle {
          var _width: number
          var _height: number
          constructor (w: number, h: number) {
            _width = w
            _height = h
          }
          get area => _width * _height
        }
        var rect = Rectangle(6, 7)
        rect.area
      ''');
      expect(result, 42);
    });

    test('static getter', () {
      final result = hetu.eval(r'''
        class Config {
          static get version => '1.0.0'
        }
        Config.version
      ''');
      expect(result, '1.0.0');
    });

    test('getter called without parentheses', () {
      final result = hetu.eval(r'''
        class Guy {
          get number => 42
        }
        var j = Guy()
        j.number
      ''');
      expect(result, 42);
    });
  });

  group('setter -', () {
    test('instance setter', () {
      final result = hetu.eval(r'''
        class Temperature {
          var _celsius: number = 0
          get fahrenheit => _celsius * 9 / 5 + 32
          set fahrenheit(value: number) {
            _celsius = (value - 32) * 5 / 9
          }
          get celsius => _celsius
        }
        var t = Temperature()
        t.fahrenheit = 32
        t.celsius
      ''');
      expect(result, 0);
    });

    test('setter with validation', () {
      final result = hetu.eval(r'''
        class Positive {
          var _value: number = 0
          set value(v: number) {
            _value = v
          }
          get value => _value
        }
        var p = Positive()
        p.value = 42
        p.value
      ''');
      expect(result, 42);
    });
  });

  group('getter/setter combined -', () {
    test('getter and setter work together', () {
      final result = hetu.eval(r'''
        class Person {
          var _name: string = ''
          get name => _name
          set name(n: string) {
            _name = n
          }
        }
        var p = Person()
        p.name = 'Alice'
        p.name
      ''');
      expect(result, 'Alice');
    });
  });
}
