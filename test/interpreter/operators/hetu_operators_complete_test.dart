import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

/// 河图脚本语言运算符完整性测试套件
///
/// 该测试套件根据河图脚本语言的运算符优先级表进行设计，测试所有支持的运算符类型：
///
/// 优先级（从高到低）：
/// 16. 后缀一元运算符: e., e?., e++, e--, e1[e2], e()
/// 15. 前缀一元运算符: -e, !e, ++e, --e, await e
/// 14. 乘法运算符: *, /, ~/, %
/// 13. 加法运算符: +, -
/// 12. 位移运算符: <<, >>, >>>
/// 11. 位与运算符: &
/// 10. 位异或运算符: ^
///  9. 位或运算符: |
///  8. 关系运算符: <, >, <=, >=, as, is, is!, in, in!
///  7. 相等运算符: ==, !=
///  6. 逻辑与运算符: &&
///  5. 逻辑或运算符: ||
///  4. 空合并运算符: ??
///  3. 三元运算符: e1 ? e2 : e3
///  1. 赋值运算符: =, *=, /=, ~/=, +=, -=, ??=
///  0. 展开运算符: ...
void main() {
  final hetu = Hetu(
    config: HetuConfig(
      allowVariableShadowing: true,
      printPerformanceStatistics: false,
    ),
  );
  hetu.init();

  group('运算符优先级测试 - ', () {
    test('算术运算符优先级', () {
      // * / 比 + - 优先级高
      expect(hetu.eval('2 + 3 * 4'), 14); // 2 + (3 * 4) = 14
      expect(hetu.eval('20 - 6 / 2'), 17); // 20 - (6 / 2) = 17
      expect(hetu.eval('2 * 3 + 4 * 5'), 26); // (2 * 3) + (4 * 5) = 26
    });

    test('括号优先级覆盖', () {
      expect(hetu.eval('(2 + 3) * 4'), 20);
      expect(hetu.eval('(20 - 6) / 2'), 7);
    });

    test('一元运算符优先级', () {
      final result = hetu.eval(r'''
        var a = 5
        var b = -a * 2
        b
      ''');
      expect(result, -10); // -a 先计算，然后 * 2
    });
  });

  group('算术运算符 - ', () {
    test('基本算术运算', () {
      expect(hetu.eval('5 + 3'), 8);
      expect(hetu.eval('10 - 4'), 6);
      expect(hetu.eval('6 * 7'), 42);
      expect(hetu.eval('15 / 3'), 5);
      expect(hetu.eval('17 % 5'), 2);
    });

    test('整数除法', () {
      expect(hetu.eval('17 ~/ 5'), 3);
      expect(hetu.eval('20 ~/ 6'), 3);
    });

    test('负数运算', () {
      expect(hetu.eval('-5 + 3'), -2);
      expect(hetu.eval('5 + -3'), 2);
      expect(hetu.eval('-5 * -3'), 15);
    });
  });

  group('位运算符 - ', () {
    test('按位与运算', () {
      expect(hetu.eval('5 & 3'), 1); // 101 & 011 = 001
      expect(hetu.eval('12 & 7'), 4); // 1100 & 0111 = 0100
    });

    test('按位或运算', () {
      expect(hetu.eval('5 | 3'), 7); // 101 | 011 = 111
      expect(hetu.eval('8 | 4'), 12); // 1000 | 0100 = 1100
    });

    test('按位异或运算', () {
      expect(hetu.eval('5 ^ 3'), 6); // 101 ^ 011 = 110
      expect(hetu.eval('8 ^ 4'), 12); // 1000 ^ 0100 = 1100
    });

    test('位移运算符', () {
      expect(hetu.eval('5 << 2'), 20); // 101 << 2 = 10100
      expect(hetu.eval('20 >> 2'), 5); // 10100 >> 2 = 101
      expect(hetu.eval('20 >>> 2'), 5); // 无符号右移
    });
  });

  group('比较运算符 - ', () {
    test('关系运算符', () {
      expect(hetu.eval('5 > 3'), true);
      expect(hetu.eval('3 > 5'), false);
      expect(hetu.eval('5 >= 5'), true);
      expect(hetu.eval('4 >= 5'), false);
      expect(hetu.eval('3 < 5'), true);
      expect(hetu.eval('5 < 3'), false);
      expect(hetu.eval('5 <= 5'), true);
      expect(hetu.eval('6 <= 5'), false);
    });

    test('相等运算符', () {
      expect(hetu.eval('5 == 5'), true);
      expect(hetu.eval('5 == 3'), false);
      expect(hetu.eval('5 != 3'), true);
      expect(hetu.eval('5 != 5'), false);
    });

    test('字符串比较', () {
      expect(hetu.eval('"abc" == "abc"'), true);
      expect(hetu.eval('"abc" != "def"'), true);
      // 注意：字符串的大小比较运算符在 Hetu 中可能不支持
    });
  });

  group('逻辑运算符 - ', () {
    test('逻辑与运算', () {
      expect(hetu.eval('true && true'), true);
      expect(hetu.eval('true && false'), false);
      expect(hetu.eval('false && true'), false);
      expect(hetu.eval('false && false'), false);
    });

    test('逻辑或运算', () {
      expect(hetu.eval('true || true'), true);
      expect(hetu.eval('true || false'), true);
      expect(hetu.eval('false || true'), true);
      expect(hetu.eval('false || false'), false);
    });

    test('逻辑非运算', () {
      expect(hetu.eval('!true'), false);
      expect(hetu.eval('!false'), true);
    });

    test('短路求值', () {
      final result = hetu.eval(r'''
        var called = false
        function sideEffect() {
          called = true
          return true
        }
        var result = false && sideEffect()
        [result, called]
      ''');
      expect(result, [false, false]); // sideEffect 不应该被调用
    });
  });

  group('空值运算符 - ', () {
    test('空合并运算符', () {
      expect(hetu.eval('null ?? "default"'), "default");
      expect(hetu.eval('"value" ?? "default"'), "value");
      expect(hetu.eval('0 ?? "default"'), 0);
      expect(hetu.eval('false ?? "default"'), false);
    });

    test('空合并赋值', () {
      final result = hetu.eval(r'''
        var a = null
        a ??= "assigned"
        a
      ''');
      expect(result, "assigned");
    });

    test('可空成员访问', () {
      final result1 = hetu.eval(r'''
        var obj = null
        obj?.property
      ''');
      expect(result1, null);

      final result2 = hetu.eval(r'''
        var obj = { property: "value" }
        obj?.property
      ''');
      expect(result2, "value");
    });

    test('可空方法调用', () {
      final result = hetu.eval(r'''
        var obj = null
        obj?.someMethod()
      ''');
      expect(result, null);
    });

    test('可空链式调用', () {
      final result = hetu.eval(r'''
        var obj = null
        obj?.prop1?.prop2?.method()
      ''');
      expect(result, null);
    });
  });

  group('三元运算符 - ', () {
    test('基本三元运算', () {
      expect(hetu.eval('true ? "yes" : "no"'), "yes");
      expect(hetu.eval('false ? "yes" : "no"'), "no");
    });

    test('嵌套三元运算', () {
      final result = hetu
          .eval('5 > 3 ? (2 > 1 ? "both true" : "first true") : "first false"');
      expect(result, "both true");
    });
  });

  group('赋值运算符 - ', () {
    test('复合赋值', () {
      final tests = [
        ['var a = 10; a += 5; a', 15],
        ['var b = 10; b -= 3; b', 7],
        ['var c = 4; c *= 3; c', 12],
        ['var d = 15; d /= 3; d', 5],
        ['var e = 17; e ~/= 5; e', 3],
      ];

      for (var test in tests) {
        expect(hetu.eval(test[0] as String), test[1]);
      }
    });
  });

  group('自增自减运算符 - ', () {
    test('前置自增', () {
      final result = hetu.eval(r'''
        var a = 5
        var b = ++a
        [a, b]
      ''');
      expect(result, [6, 6]);
    });

    test('后置自增', () {
      final result = hetu.eval(r'''
        var a = 5
        var b = a++
        [a, b]
      ''');
      expect(result, [6, 5]);
    });

    test('前置自减', () {
      final result = hetu.eval(r'''
        var a = 5
        var b = --a
        [a, b]
      ''');
      expect(result, [4, 4]);
    });

    test('后置自减', () {
      final result = hetu.eval(r'''
        var a = 5
        var b = a--
        [a, b]
      ''');
      expect(result, [4, 5]);
    });
  });

  group('成员访问运算符 - ', () {
    test('点运算符', () {
      final result = hetu.eval(r'''
        class Person {
          var name = "John"
        }
        var p = Person()
        p.name
      ''');
      expect(result, "John");
    });

    test('下标运算符', () {
      final result1 = hetu.eval(r'''
        var list = [1, 2, 3, 4, 5]
        list[2]
      ''');
      expect(result1, 3);

      final result2 = hetu.eval(r'''
        var map = {"key": "value", "num": 42}
        map["key"]
      ''');
      expect(result2, "value");
    });

    test('方法调用', () {
      final result = hetu.eval(r'''
        class Calculator {
          function add(a, b) {
            return a + b
          }
        }
        var calc = Calculator()
        calc.add(3, 5)
      ''');
      expect(result, 8);
    });
  });

  group('类型测试运算符 - ', () {
    test('is 运算符', () {
      final result = hetu.eval(r'''
        var value = 42
        value is num
      ''');
      expect(result, true);
    });

    test('is! 运算符', () {
      final result = hetu.eval(r'''
        var value = "hello"
        value is! num
      ''');
      expect(result, true);
    });
  });

  group('展开运算符 - ', () {
    test('函数调用中的展开', () {
      final result = hetu.eval(r'''
        function sum(a, b) {
          return a + b
        }
        var numbers = [1, 2]
        sum(...numbers)
      ''');
      expect(result, 3);
    });

    test('列表字面量中的展开', () {
      final result = hetu.eval(r'''
        var first = [1, 2]
        var second = [3, 4]
        var combined = [0, ...first, ...second, 5]
        combined.length
      ''');
      expect(result, 6);
    });

    test('结构体字面量中的展开', () {
      final result = hetu.eval(r'''
        var base = { a: 1, b: 2 }
        var extended = { ...base, c: 3, a: 10 }
        extended.a
      ''');
      expect(result, 10); // 后面的值覆盖前面的
    });
  });

  group('复杂表达式测试 - ', () {
    test('算术运算符优先级', () {
      expect(hetu.eval('2 + 3 * 4'), 14);
      expect(hetu.eval('14 > 10'), true);
      expect(hetu.eval('5 < 8'), true);
      expect(hetu.eval('true && true'), true);
    });

    test('复杂赋值与成员访问', () {
      final result = hetu.eval(r'''
        var obj = { counter: 10 }
        obj.counter += 5 * 2
        obj.counter *= 2
        obj.counter
      ''');
      expect(result, 40); // ((10 + (5 * 2)) * 2) = 40
    });

    test('链式空值检查', () {
      final result1 = hetu.eval(r'''
        var deep = {
          level1: {
            level2: {
              value: "found"
            }
          }
        }
        deep?.level1?.level2?.value
      ''');
      expect(result1, "found");

      final result2 = hetu.eval(r'''
        var deep = {
          level1: null
        }
        deep?.level1?.level2?.value
      ''');
      expect(result2, null);
    });
  });

  group('边界情况测试 - ', () {
    test('除零处理', () {
      // Hetu 返回 Infinity 而不是抛出异常
      final result = hetu.eval('5 / 0');
      expect(result, double.infinity);
    });

    test('深层表达式嵌套', () {
      final result = hetu.eval('((((5 + 3) * 2) - 4) / 2) % 3');
      expect(result, 0); // 6 % 3 = 0
    });

    test('类型不匹配运算', () {
      // 测试字符串和数字相加是否会报错
      expect(() => hetu.eval('"number: " + 42'), throwsA(anything));
    });

    test('布尔运算', () {
      // 测试布尔值与数字运算
      expect(() => hetu.eval('true + 1'), throwsA(anything));
    });
  });
}
