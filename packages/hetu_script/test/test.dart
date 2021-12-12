import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
  /// 容貌最大值: 100.0
  final beautyMax = 100.0

  /// 获得随机偏好
  /// 大多数人的偏好都会接近于标准的100
  /// 取值离100越远，随机出的可能性越低
  /// 公式: y=\frac{6x-6}{5x-6}
  fun createRandomFavors() {
    final x = Math.random()
    return ((x * 6 - 6) / (5 * x - 6)) * 100
  }
  
  /// 容貌评价的计算公式
  /// 每个角色自身有一个容貌值，这个数值代表大众眼中的评价
  /// 每个角色都会有一个对特定容貌值的偏好
  /// 本公式会利用这两个数值，计算某个角色对另一个角色的容貌的评价
  /// beauty 是对方的容貌，0 <= beauty <= 100
  /// favors 是该角色的偏好，0 <= favors <= 100
  fun getBeautyScore(beauty: float, {favors: float}) -> num {
    assert 0.0 <= beauty && beauty <= beautyMax
    if (favors != null) {
      assert 0.0 <= favors && favors <= beautyMax
    }
    if (beauty < ((favors + beautyMax) / 2)) {
      return (-(beauty - favors) * (beauty - favors)) / 20 + beautyMax
    } else {
      return (-(beauty - beautyMax) * (beauty - beautyMax)) / 20 + beautyMax
    }
  }

  for (var i = 0; i <= 100; ++i) {
    print(createRandomFavors())
  }
  
  for (var i = 0; i <= 100; i = i + 10) {
    final score = getBeautyScore(i, favors: 100)
    print('i: ${i}, score: ${score}')
  }
  ''', isScript: true);
}
