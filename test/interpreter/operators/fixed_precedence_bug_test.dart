import 'package:test/test.dart';
import 'package:hetu_script/hetu_script.dart';

/// 测试修复的运算符优先级 bug
///
/// 这个测试专门验证修复的递归下降解析器中运算符优先级 bug。
/// 之前的实现中，所有二元运算符的右操作数都错误地调用了 _parseTernaryExpr()，
/// 导致运算符优先级混乱。现在修复为正确的递归调用。
void main() {
  final hetu = Hetu(
    config: HetuConfig(
      allowVariableShadowing: true,
      printPerformanceStatistics: false,
    ),
  );
  hetu.init();

  group('修复的运算符优先级测试 - ', () {
    test('逻辑运算符优先级 (&&高于||)', () {
      // 之前的 bug: false && false || true 会被错误解析
      // 正确应该是: (false && false) || true = false || true = true
      expect(hetu.eval('false && false || true'), true);
      expect(hetu.eval('true || false && false'), true);
      expect(hetu.eval('false || false && true'), false);

      // 验证括号可以改变优先级
      expect(hetu.eval('false && (false || true)'), false);
      expect(hetu.eval('(true || false) && false'), false);
    });

    test('位运算符优先级 (&高于^高于|)', () {
      // 测试 & 优先级高于 ^
      expect(hetu.eval('5 ^ 3 & 7'), 6); // 5 ^ (3 & 7) = 5 ^ 3 = 6
      expect(hetu.eval('8 ^ 4 & 12'), 12); // 8 ^ (4 & 12) = 8 ^ 4 = 12

      // 测试 ^ 优先级高于 |
      expect(hetu.eval('1 | 2 ^ 3'), 1); // 1 | (2 ^ 3) = 1 | 1 = 1
      expect(hetu.eval('4 | 5 ^ 1'), 4); // 4 | (5 ^ 1) = 4 | 4 = 4

      // 测试 & 优先级高于 |
      expect(hetu.eval('1 | 2 & 4'), 1); // 1 | (2 & 4) = 1 | 0 = 1
      expect(hetu.eval('7 | 8 & 15'), 15); // 7 | (8 & 15) = 7 | 8 = 15
    });

    test('算术运算符与位运算符的优先级', () {
      // 算术运算符优先级高于位运算符
      expect(hetu.eval('1 + 2 & 3'), 3); // (1 + 2) & 3 = 3 & 3 = 3
      expect(hetu.eval('4 * 2 | 1'), 9); // (4 * 2) | 1 = 8 | 1 = 9
      expect(hetu.eval('5 - 1 ^ 2'), 6); // (5 - 1) ^ 2 = 4 ^ 2 = 6
    });

    test('位移运算符优先级', () {
      // 位移优先级高于位运算
      expect(hetu.eval('1 | 2 << 1'), 5); // 1 | (2 << 1) = 1 | 4 = 5
      expect(hetu.eval('8 & 16 >> 1'), 8); // 8 & (16 >> 1) = 8 & 8 = 8
      expect(hetu.eval('3 ^ 4 << 1'), 11); // 3 ^ (4 << 1) = 3 ^ 8 = 11
    });

    test('空合并运算符优先级', () {
      // ?? 优先级低于逻辑运算符
      expect(hetu.eval('null ?? false || true'),
          true); // (null ?? false) || true = false || true = true
      expect(hetu.eval('null ?? true && false'),
          false); // (null ?? true) && false = true && false = false

      // 但高于三元运算符 (这是原来的bug区域)
      expect(hetu.eval('null ?? true ? "yes" : "no"'),
          "yes"); // (null ?? true) ? "yes" : "no" = true ? "yes" : "no" = "yes"
    });

    test('复杂混合表达式优先级', () {
      // 测试多个运算符混合的情况
      expect(hetu.eval('2 + 3 * 4 & 7'), 6); // (2 + (3 * 4)) & 7 = 14 & 7 = 6
      expect(hetu.eval('1 | 2 & 3 + 4'),
          3); // 1 | (2 & (3 + 4)) = 1 | (2 & 7) = 1 | 2 = 3
      expect(hetu.eval('5 ^ 2 * 3 | 1'),
          3); // (5 ^ (2 * 3)) | 1 = (5 ^ 6) | 1 = 3 | 1 = 3
    });

    test('逻辑运算符与比较运算符优先级', () {
      // 比较运算符优先级高于逻辑运算符
      expect(hetu.eval('5 > 3 && 2 < 4'),
          true); // (5 > 3) && (2 < 4) = true && true = true
      expect(hetu.eval('1 == 1 || 2 != 2'),
          true); // (1 == 1) || (2 != 2) = true || false = true
      expect(hetu.eval('false || 5 > 3 && 2 < 1'),
          false); // false || ((5 > 3) && (2 < 1)) = false || (true && false) = false || false = false
    });

    test('验证原始错误的表达式现在能正确工作', () {
      // 这些是之前测试中失败的表达式，现在应该正确了
      expect(hetu.eval('false && false || true'), true);
      expect(hetu.eval('1 | 2 & 4'), 1);
      expect(hetu.eval('5 ^ 3 & 7'), 6);

      // 验证没有破坏其他功能
      expect(hetu.eval('2 + 3 * 4'), 14);
      expect(hetu.eval('true ? "yes" : "no"'), "yes");
      expect(hetu.eval('null ?? "default"'), "default");
    });
  });
}
