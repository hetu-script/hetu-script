import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu(
    config: HetuConfig(
      printPerformanceStatistics: false,
    ),
  );
  hetu.init();

  group('struct -', () {
    test('basics', () {
      final result = hetu.eval(r'''
        var foo = {
          value: 42,
          greeting: 'hi!'
        }
        foo.value = 'ha!'
        foo.world = 'everything'
        foo.toString()
      ''');
      expect(
        result,
        r'''{
  value: 'ha!',
  greeting: 'hi!',
  world: 'everything'
}''',
      );
    });
    test('fromJson', () {
      final jsonData = {
        "name": "Aleph",
        "type": "novel",
        "volumes": 7,
      };
      final result = hetu.eval(
          r'''
            function fromJsonTest(data) {
              final obj = Object.fromJSON(data)
              return obj.volumes
            }
          ''',
          invoke: 'fromJsonTest',
          positionalArgs: [jsonData]);
      expect(
        result,
        7,
      );
    });
    test('containsKey', () {
      final result = hetu.eval(r'''
        var ht = {
          name: 'Hetu',
          age: 1
        }
        ht.hasOwnProperty('toJSON') // false
      ''');
      expect(
        result,
        false,
      );
    });
    test('named', () {
      final result = hetu.eval(r'''
        struct Named {
          var name = 'Unity'
          var age = 17
        }
        final n = Named()
        n.age = 42
        Named.age
      ''');
      expect(
        result,
        17,
      );
    });

    test('named constructor', () {
      final result = hetu.eval(r'''
        struct DialogContentData {
          constructor ({
            localeKeys,
          }) {
            this.localeKeys = localeKeys
          }

          constructor fromData(data) : this(
            localeKeys: data.localeKeys,
          ) {}
        }

        final dlg = DialogContentData.fromData({
          localeKeys: ['a', 'b']
        })

        dlg.localeKeys
      ''');
      expect(result, ['a', 'b']);
    });

    test('assign & merge', () {
      final result = hetu.eval(r'''

        let a = {a: 1}
        let b = {a: 4, b: 4}
        let c = {a: 42, c: 5}

        Object.assign(a, b)
        a.a
      ''');
      expect(result, 4);
    });

    test('prototype chain with extends', () {
      final result = hetu.eval(r'''
        struct Animal {
          function speak() {
            return 'generic sound'
          }
        }
        struct Dog extends Animal {
          function speak() {
            return 'woof'
          }
        }
        var d = Dog()
        d.speak()
      ''');
      expect(result, 'woof');
    });

    test('prototype inheritance - parent method', () {
      final result = hetu.eval(r'''
        struct ParentProto {
          function breathe() {
            return true
          }
        }
        struct ChildProto extends ParentProto {
          var name = 'kitty'
        }
        var cp = ChildProto()
        cp.breathe()
      ''');
      expect(result, true);
    });

    test('struct with mixin', () {
      final result = hetu.eval(r'''
        struct MixinFly {
          function fly() {
            return 'flying'
          }
        }
        struct MixinBird with MixinFly {
          var name = 'eagle'
        }
        var mb = MixinBird()
        mb.fly()
      ''');
      expect(result, 'flying');
    });

    test('spread in struct with override', () {
      final result = hetu.eval(r'''
        var defaults = { name: 'unknown', age: 0 }
        var person = {
          ...defaults,
          name: 'John',
        }
        person.name
      ''');
      expect(result, 'John');
    });

    test('nested struct access', () {
      final result = hetu.eval(r'''
        var outer = {
          inner: { value: 42 }
        }
        outer.inner.value
      ''');
      expect(result, 42);
    });

    test('call struct constructor within another struct constructor', () {
      final obj = hetu.eval(r'''
        struct Tile {
          var left
          var right

          constructor (left, right) {
            this.left = left
            this.right = right
          }
        }

        struct Test {
          constructor (left, right) {
            Object.assign(this, Tile(left, right))
          }
        }

        let t1 = Test(1, 2)
        t1
      ''');
      expect(obj['left'], 1);
      expect(obj['right'], 2);
    });

    test('nested constructor calls within constructor body', () {
      final result = hetu.eval(r'''
        struct Inner {
          var value

          constructor (value) {
            this.value = value
          }
        }

        struct Middle {
          var inner

          constructor (value) {
            this.inner = Inner(value)
          }
        }

        struct Outer {
          var middle

          constructor (value) {
            this.middle = Middle(value)
          }
        }

        let o1 = Outer(42)
        o1.middle.inner.value
      ''');
      expect(result, 42);
    });

    test('constructor with multiple Object.assign calls', () {
      final c1 = hetu.eval(r'''
        struct A {
          var a

          constructor (a) {
            this.a = a
          }
        }

        struct B {
          var b

          constructor (b) {
            this.b = b
          }
        }

        struct C {
          constructor (a, b) {
            Object.assign(this, A(a))
            Object.assign(this, B(b))
          }
        }

        let c1 = C(1, 2)
        c1
      ''');
      expect(c1['a'], 1);
      expect(c1['b'], 2);
    });

    test('constructor return value is instance not last expression', () {
      final f = hetu.eval(r'''
        struct Foo {
          var x
          var y

          constructor (a, b) {
            this.x = a
            this.y = b
          }
        }

        let f1 = Foo('hello', 'world')
        f1
      ''');
      expect(f['x'], 'hello');
      expect(f['y'], 'world');
    });

    test('constructor call as argument to function', () {
      final result = hetu.eval(r'''
        struct Point {
          var x
          var y

          constructor (x, y) {
            this.x = x
            this.y = y
          }
        }

        function getX(pt) {
          return pt.x
        }

        getX(Point(10, 20))
      ''');
      expect(result, 10);
    });
  });
}
